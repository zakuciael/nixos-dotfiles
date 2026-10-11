# Advanced miette patterns

Read this when implementing multi-error reports, delayed source attachment,
dynamic help, or severity beyond the basics in `SKILL.md`.

## Related diagnostics

Collect several diagnostics into one report with `#[related]`:

```rust
use miette::Diagnostic;
use thiserror::Error;

#[derive(Debug, Error, Diagnostic)]
#[error("configuration validation failed")]
#[diagnostic(code(config::validation))]
pub struct ValidationFailed {
    #[related]
    pub issues: Vec<ConfigIssue>,
}

#[derive(Debug, Error, Diagnostic)]
#[error("{message}")]
#[diagnostic(code(config::issue))]
pub struct ConfigIssue {
    pub message: String,
    #[label("here")]
    pub at: miette::SourceSpan,
}
```

When many related errors share one document, put `#[source_code]` on the parent
and labels on the children (children may omit their own source).

## Delayed source code

Emit spans first, attach source later with `.with_source_code(...)`:

```rust
use miette::{Diagnostic, SourceSpan};
use thiserror::Error;

#[derive(Debug, Error, Diagnostic)]
#[error("bad fragment")]
pub struct FragmentError {
    #[label]
    pub at: SourceSpan,
}

fn parse_fragment() -> miette::Result<()> {
    Err(FragmentError { at: (7..11).into() })?;
    Ok(())
}

fn main() -> miette::Result<()> {
    parse_fragment().map_err(|err| err.with_source_code(String::from("source code")))
}
```

Useful when lower layers should stay source-agnostic (e.g. shared parsers) and
the caller owns the file buffer.

## Dynamic help text

Static `help("...")` covers most cases. For computed advice, use a field:

```rust
use miette::Diagnostic;
use thiserror::Error;

#[derive(Debug, Error, Diagnostic)]
#[error("unsupported edition `{edition}`")]
pub struct EditionError {
    pub edition: String,
    #[help]
    pub advice: Option<String>,
}
```

## Severity

Mark non-fatal diagnostics explicitly when the reporter should treat them as
warnings (or other levels):

```rust
#[diagnostic(severity(Warning))]
```

Default is error-level reporting when omitted.

## Diagnostic code URLs

- Hard-coded or formatted: `url("https://example.com/errors#{}", self.code().unwrap())`
- Library types at crate root: `url(docsrs)` → docs.rs page for that type

Keep codes stable (`crate::module::snake_case`) so links and telemetry stay useful.
