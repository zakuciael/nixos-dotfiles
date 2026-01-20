#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "typer",
# ]
# ///
"""
Remove duplicate crates from Cargo.lock, keeping the crates.io version.

When a crate exists both from crates.io and from a git source with the same
name and version, this script removes the git-sourced entry and updates all
references to use the crates.io version.
"""

import re
import sys
from pathlib import Path

import typer


def parse_cargo_lock(content: str) -> list[dict]:
    """Parse Cargo.lock into a list of package entries."""
    packages = []
    current_pkg = {}
    current_key = None
    in_array = False
    array_lines = []

    for line in content.split("\n"):
        # Start of a new package
        if line == "[[package]]":
            if current_pkg:
                packages.append(current_pkg)
            current_pkg = {"_raw_deps": []}
            current_key = None
            in_array = False
            continue

        # Skip empty lines and comments at top level
        if not current_pkg:
            continue

        # Handle array continuation
        if in_array:
            if line.startswith("]"):
                current_pkg[current_key] = array_lines
                in_array = False
                array_lines = []
                current_key = None
            else:
                # Strip the line and remove quotes/comma
                dep = line.strip().strip(",").strip('"')
                if dep:
                    array_lines.append(dep)
            continue

        # Key = value pairs
        if "=" in line and not line.startswith(" "):
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip()

            if value == "[":
                # Start of array
                in_array = True
                current_key = key
                array_lines = []
            elif value.startswith("[") and value.endswith("]"):
                # Inline array
                inner = value[1:-1]
                items = [x.strip().strip('"') for x in inner.split(",") if x.strip()]
                current_pkg[key] = items
            else:
                # Simple value
                current_pkg[key] = value.strip('"')

    if current_pkg:
        packages.append(current_pkg)

    return packages


def find_duplicates(packages: list[dict]) -> dict[tuple[str, str], list[dict]]:
    """Find packages with same name and version but different sources."""
    by_name_version = {}
    for pkg in packages:
        name = pkg.get("name", "")
        version = pkg.get("version", "")
        key = (name, version)
        if key not in by_name_version:
            by_name_version[key] = []
        by_name_version[key].append(pkg)

    # Return only duplicates
    return {k: v for k, v in by_name_version.items() if len(v) > 1}


def is_crates_io(pkg: dict) -> bool:
    """Check if package is from crates.io."""
    source = pkg.get("source", "")
    return source.startswith("registry+https://github.com/rust-lang/crates.io-index")


def is_git_source(pkg: dict) -> bool:
    """Check if package is from a git source."""
    source = pkg.get("source", "")
    return source.startswith("git+")


def get_full_spec(pkg: dict) -> str:
    """Get the full package specification as used in dependency lists."""
    name = pkg.get("name", "")
    version = pkg.get("version", "")
    source = pkg.get("source", "")
    if source:
        return f"{name} {version} ({source})"
    return f"{name} {version}"


def get_simple_spec(pkg: dict) -> str:
    """Get simplified spec (just name, or name + version if needed)."""
    return pkg.get("name", "")


def serialize_package(pkg: dict) -> str:
    """Serialize a package back to TOML format."""
    lines = ["[[package]]"]

    # Order matters for readability
    key_order = [
        "name",
        "version",
        "source",
        "checksum",
        "dependencies",
        "build-dependencies",
        "features",
    ]

    written_keys = set()
    for key in key_order:
        if key in pkg and key != "_raw_deps":
            written_keys.add(key)
            value = pkg[key]
            if isinstance(value, list):
                if value:
                    lines.append(f"{key} = [")
                    for item in value:
                        lines.append(f' "{item}",')
                    lines.append("]")
            else:
                lines.append(f'{key} = "{value}"')

    # Write any remaining keys
    for key, value in pkg.items():
        if key in written_keys or key == "_raw_deps":
            continue
        if isinstance(value, list):
            if value:
                lines.append(f"{key} = [")
                for item in value:
                    lines.append(f' "{item}",')
                lines.append("]")
        else:
            lines.append(f'{key} = "{value}"')

    return "\n".join(lines)


def dedupe_cargo_lock(content: str, dry_run: bool = False) -> tuple[str, list[str]]:
    """
    Remove duplicate crates, keeping crates.io versions.
    Returns (new_content, list_of_changes).
    """
    packages = parse_cargo_lock(content)
    duplicates = find_duplicates(packages)

    if not duplicates:
        return content, ["No duplicates found."]

    changes = []
    packages_to_remove = set()
    replacements = {}  # old_spec -> new_spec

    for (name, version), pkgs in duplicates.items():
        crates_io_pkgs = [p for p in pkgs if is_crates_io(p)]
        git_pkgs = [p for p in pkgs if is_git_source(p)]

        if len(crates_io_pkgs) == 1 and len(git_pkgs) >= 1:
            simple_spec = name  # Just the name for the replacement

            for remove in git_pkgs:
                remove_spec = get_full_spec(remove)
                packages_to_remove.add(remove_spec)
                replacements[remove_spec] = simple_spec
                changes.append(
                    f"Remove: {name} {version} (git) -> keep crates.io version"
                )

        elif len(crates_io_pkgs) == 0 and len(git_pkgs) > 1:
            changes.append(
                f"Warning: {name} {version} has multiple git sources, skipping"
            )
        elif len(crates_io_pkgs) > 1:
            changes.append(
                f"Warning: {name} {version} has multiple crates.io sources, skipping"
            )
        else:
            changes.append(
                f"Warning: {name} {version} has unexpected source combination, skipping"
            )

    if dry_run:
        return content, changes

    # Build new package list, excluding removed packages
    new_packages = []
    for pkg in packages:
        spec = get_full_spec(pkg)
        if spec in packages_to_remove:
            continue

        # Update dependencies to use simple specs
        for dep_key in ["dependencies", "build-dependencies"]:
            if dep_key in pkg:
                new_deps = []
                for dep in pkg[dep_key]:
                    replaced = False
                    for old_spec, new_spec in replacements.items():
                        # Check if this dependency references a removed package
                        # Dependencies look like "name version (source)" or just "name"
                        if old_spec in dep or dep.startswith(old_spec.split()[0] + " "):
                            # Extract just the crate name from the dependency
                            dep_name = dep.split()[0]
                            for (rname, rver), _ in duplicates.items():
                                if dep_name == rname:
                                    new_deps.append(dep_name)
                                    replaced = True
                                    break
                            if replaced:
                                break
                    if not replaced:
                        new_deps.append(dep)
                pkg[dep_key] = new_deps

        new_packages.append(pkg)

    # Reconstruct the file
    # First, preserve the header (version and metadata before first [[package]])
    header_match = re.match(r"^(.*?)(?=\[\[package\]\])", content, re.DOTALL)
    header = (
        header_match.group(1)
        if header_match
        else "# This file is automatically @generated by Cargo.\n# It is not intended for manual editing.\n"
    )

    # Serialize all packages
    output_parts = [header.rstrip()]
    for pkg in new_packages:
        output_parts.append("")
        output_parts.append(serialize_package(pkg))

    return "\n".join(output_parts) + "\n", changes


app = typer.Typer(
    help="Remove duplicate crates from Cargo.lock, keeping crates.io versions."
)


@app.command()
def main(
    cargo_lock: Path = typer.Argument(help="Path to Cargo.lock file"),
    dry_run: bool = typer.Option(
        False,
        "--dry-run",
        "-n",
        help="Show what would be changed without modifying files",
    ),
    output: Path | None = typer.Option(
        None, "--output", "-o", help="Output file (default: modify input file in place)"
    ),
    quiet: bool = typer.Option(
        False, "--quiet", "-q", help="Suppress informational output"
    ),
) -> None:
    """Remove duplicate crates from Cargo.lock, keeping crates.io versions."""
    if not cargo_lock.exists():
        typer.echo(f"Error: File not found: {cargo_lock}", err=True)
        raise typer.Exit(1)

    content = cargo_lock.read_text()
    new_content, changes = dedupe_cargo_lock(content, dry_run=dry_run)

    if not quiet:
        for change in changes:
            typer.echo(change, err=True)

    if dry_run:
        if not quiet:
            typer.echo("\n[Dry run - no changes made]", err=True)
    else:
        output_path = output or cargo_lock
        output_path.write_text(new_content)
        if not quiet:
            typer.echo(f"\nUpdated {output_path}", err=True)


if __name__ == "__main__":
    app()
