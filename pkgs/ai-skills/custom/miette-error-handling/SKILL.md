---
name: miette-error-handling
description: >
  Design and implement robust, readable, domain-correct Rust error handling with
  miette diagnostics and thiserror. Use whenever writing or refactoring Rust
  errors, Results, parsers, CLIs, config loaders, or any fallible API — even if
  the user only says "add error handling", "make errors nicer", "use thiserror",
  or asks about spans/labels/help text. Prefer this over ad-hoc String errors,
  bare anyhow in libraries, or unannotated std::io::Error returns.
---

# Rust Diagnostic Errors with miette + thiserror

Produce errors that are typed at the domain boundary, readable in the terminal,
and actionable for the user. Combine `thiserror` for structure with `miette` for
diagnostics (codes, help, spans, related reports).

## Core rules

1. **No generic production errors.** Do not return raw `String`, `&str`,
   `Box<dyn Error>`, or unmapped foreign errors from domain modules.
2. **Split library vs application shapes.**
   - Libraries: concrete `thiserror` + `miette::Diagnostic` types; wrap foreign
     errors in enum variants. Do **not** return `miette::Report` from public APIs.
   - Applications/binaries: `miette::Result`, `.into_diagnostic()`, and
     `.wrap_err(...)` / `.wrap_err_with(...)` for layered context.
3. **Enrich intentionally.** Prefer unique `code(...)`, actionable `help(...)`,
   and docs links (`url(...)` or `url(docsrs)` for library types).
4. **Point at the failure.** For user input, syntax, or parsing, attach
   `#[source_code]` plus one or more `#[label]` / `SourceSpan` fields.
5. **Keep `fancy` at the binary edge.** Enable `miette` feature `"fancy"` only in
   the top-level crate that prints reports; libraries should depend on miette
   without pulling fancy printer deps.

## Choose a pattern

| Situation | Pattern |
| --- | --- |
| Stable domain failures in a lib/crate | Typed enum/struct with `Error` + `Diagnostic` |
| Wrapping another diagnostic so labels survive | `#[error(transparent)]` + `#[diagnostic(transparent)]` |
| Parsing / lexing / config text | `NamedSource` + `SourceSpan` labels |
| App glue around foreign `std::error::Error` | `.into_diagnostic().wrap_err("...")` |
| Several issues from one pass | `#[related]` collection (see `references/advanced.md`) |
| Spans known before source is available | Delayed source via `.with_source_code(...)` (see `references/advanced.md`) |

Read `references/advanced.md` for related diagnostics, delayed source code,
dynamic help fields, and severity.

## Pattern: library / domain error

Define explicit variants. Map I/O and other foreign errors into the enum instead
of leaking them unchanged.

```rust
use miette::Diagnostic;
use thiserror::Error;

#[derive(Debug, Error, Diagnostic)]
pub enum ConfigError {
    #[error("failed to read configuration")]
    #[diagnostic(
        code(config::io),
        help("Check that the path exists and is readable.")
    )]
    Io {
        path: std::path::PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("unknown configuration key `{key}`")]
    #[diagnostic(
        code(config::unknown_key),
        url("https://example.com/docs/config#keys"),
        help("Valid keys are documented in the config schema.")
    )]
    UnknownKey { key: String },

    #[error(transparent)]
    #[diagnostic(transparent)]
    Parse(#[from] ParseError),
}
```

For types exported at the crate root, `url(docsrs)` can replace a hand-written
docs URL and links to the type page on docs.rs.

## Pattern: spans and labels

When the failure is located in text, always pair source with spans. Byte offsets
are relative to the attached source.

```rust
use miette::{Diagnostic, NamedSource, SourceSpan};
use thiserror::Error;

#[derive(Debug, Error, Diagnostic)]
#[error("invalid token in input")]
#[diagnostic(
    code(lexer::invalid_token),
    severity(Error),
    help("Tokens must be alphanumeric.")
)]
pub struct LexerError {
    #[source_code]
    pub src: NamedSource<String>,

    #[label("not allowed here")]
    pub at: SourceSpan,
}

fn lex(filename: &str, src: String) -> miette::Result<()> {
    // Example: highlight bytes [9, 13)
    Err(LexerError {
        src: NamedSource::new(filename, src),
        at: (9, 4).into(),
    })?;
    Ok(())
}
```

Notes:
- `String` also implements source; prefer `NamedSource` when a path/name helps.
- Multiple `#[label]` fields are fine; optional labels use `Option<SourceSpan>`.
- `(usize, usize)` and ranges implement `Into<SourceSpan>`.

## Pattern: application propagation

In binaries and app-internal code, prefer `miette::Result` and the `?` operator.
Convert non-diagnostic errors first, then add context.

```rust
use miette::{IntoDiagnostic, Result, WrapErr};

fn load_workspace_config() -> Result<String> {
    std::fs::read_to_string("config.toml")
        .into_diagnostic()
        .wrap_err("Failed to open the workspace configuration file")
}
```

In `main`, returning `miette::Result<()>` prints the report. For colored/snippet
output, depend on `miette` with `features = ["fancy"]` in the binary crate only:

```toml
miette = { version = "7", features = ["fancy"] }
```

Use `wrap_err_with(|| format!(...))` when building the message is non-trivial and
should run only on failure.

## Anti-patterns

- Returning `Result<T, String>` or `anyhow::Error` from a reusable library API
  when a domain enum is feasible.
- Putting `miette::Report` in a library's public signature.
- Adding `#[label]` / `SourceSpan` without any `#[source_code]` (unless you
  intentionally delay source and attach it later — see references).
- Enabling `"fancy"` in a library crate "just in case".
- Help text that restates the error without a next action.
- Catch-all `#[error(transparent)] Other(#[from] Report)` that erases domain
  codes at the boundary you control.

## Agent checklist

Before finishing error types or handling blocks:

- [ ] Domain modules use typed `thiserror` errors, not stringly failures.
- [ ] `Diagnostic` is derived (or implemented) wherever users will see reports.
- [ ] Library APIs return concrete error types; apps may use `miette::Result`.
- [ ] Span-based errors include `#[source_code]` (now or via delayed attach).
- [ ] Diagnostics include `code(...)` and actionable `help(...)` when useful.
- [ ] `"fancy"` is limited to the binary/top-level reporter crate.
- [ ] Foreign errors are wrapped or `.into_diagnostic()`'d at the boundary.

## Links

- [miette docs](https://docs.rs/miette)
- [miette crate](https://crates.io/crates/miette)
- [thiserror docs](https://docs.rs/thiserror)
