---
name: nix-language
description: Write, explain, debug, and review Nix expressions using versioned upstream language references. Use for syntax, scope, lazy evaluation, functions, strings, paths, derivations, and built-ins; NixOS service options and Nixpkgs APIs need their own references.
---

# Nix language

Read [sources.json](sources.json) for the documented release and exact upstream revision.
Establish the project's target Nix version and evaluation mode before relying on version-sensitive behaviour.
The references describe that pinned release, not necessarily the user's installed evaluator.
If versions differ, verify the relevant feature against the target version's manual or executable; preserve experimental and pure-evaluation restrictions.

## Working with expressions

Read the affected expression and its callers before changing it.
Trace argument bindings, attribute selection, and when values are forced.
Reuse existing project functions and conventions; choose the smallest correct change.
Distinguish language built-ins from functions supplied by Nixpkgs `lib`, and ordinary attribute sets from NixOS module option merging.
Do not infer package APIs or service options from this language reference.

Read only the relevant section of [the language reference](references/language.md):

- **Scope, functions, recursion:** `Scoping rules`, `Functions`, `Recursive sets`, `Let-expressions`, and `With-expressions`. Lexical bindings beat `with`; `args@{ a ? value, ... }` binds the original argument set without inserting defaults.
- **Values and operators:** `Data Types`, `List`, `Attribute Set`, `Operators`, and `Update`. `//` replaces overlapping attributes; it does not recursively merge nested sets. Parenthesise function applications used as list elements.
- **Evaluation:** `Laziness and thunks` and `Strictness`. A result's outer shape being evaluated does not mean its nested values have been checked.
- **Text and files:** `String literals`, `Interpolated expression`, `Path`, and `String context`. Paths and strings differ; interpolating a path can copy files into the store. Preserve dependency context rather than discarding it to suppress an error.
- **Derivations:** `Derivations` and `Required`. Describing a derivation, evaluating it, and building its outputs are different operations. Do not treat language derivation attributes as NixOS options.

Consult [selected built-ins](references/builtins.md) for exact argument behaviour and availability notices.
For built-ins or topics outside the selection, follow the versioned upstream manual links in the references.
Do not assume a function exists just because an unrelated library provides a similarly named function.
For idioms and reproducibility practice (`rec`, `with`, lookup paths, pinning, source paths), read nix.dev's [best practices](https://nix.dev/guides/best-practices); it is not bundled here.

## Verification

Run the project's relevant checks after a change.
For a controlled, self-contained expression, evaluate an assertion or expected result with the target Nix executable.
Syntax checks alone do not prove evaluation success; evaluation alone does not prove a derivation builds.
For lazy results, force the values the change actually affects (for example with `builtins.deepSeq`), rather than checking only the outer set.

Evaluation can read files, fetch inputs, or trigger builds through import-from-derivation.
Inspect unknown expressions before executing them and respect the task's existing permissions.
Use controlled examples for language checks; do not run upstream shell examples as setup instructions.
If execution is unavailable, explain the reasoning and clearly report that validation was limited to inspection.
Report the version and checks actually run; never imply other agents or evaluator versions were tested.

## Nix style

- Never search `/nix/store` (for example `find /nix/store/*foo-* -name libfoo.so`)
  and never copy a literal store path. Find the providing package with
  `nix-locate`, and refer to it through Nix: `${pkgs.foo}/lib` or
  `lib.makeLibraryPath [ pkgs.foo ]`.
- Do not quote attribute names that are valid identifiers
  (`[A-Za-z_][A-Za-z0-9_'-]*`, dashes included). Write `pkgs.foo-bar` and
  `packages.x86_64-linux`, not `pkgs."foo-bar"`. Quote only other names
  (`".config/foo"`, `"2.0"`), the keywords
  `assert else if in inherit let or rec then with`, and interpolations
  (`"${name}"`). Upstream examples in references sometimes quote needlessly;
  do not copy that style.
