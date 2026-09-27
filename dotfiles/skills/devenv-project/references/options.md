# Options

devenv v2.3.1; upstream revision `2418e1b43797c44de5166176622c8d8fa0149871`.

Modified excerpts from the devenv contributors; see [LICENSE](../LICENSE). Source citations are pinned; devenv.sh links follow the moving public site.

- [languages/python.md: Getting started](#section-1)
- [languages/python.md: Virtual environments](#section-2)
- [languages/rust.md: Getting started](#section-3)
- [languages/javascript.md: languages.javascript.enable](#section-4)
- [languages/go.md: languages.go.enable](#section-5)
- [services/postgres.md: services.postgres.enable](#section-6)
- [Selected option records](#selected-options)

<a id="section-1"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/languages/python.md)

## Getting started

To add Python to your project, enable it in your `devenv.nix`:

```nix
{
  languages.python.enable = true;
}
```

This gives you `python3` and [pip](https://pip.pypa.io/) in your shell, using the version of Python that ships with your nixpkgs input.

<a id="section-2"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/languages/python.md)

## Virtual environments

Python projects typically use [virtual environments](https://docs.python.org/3/library/venv.html) to isolate dependencies.
devenv can create and manage one for you:

```nix
{
  languages.python = {
    enable = true;
    venv.enable = true;
  };
}
```

The virtual environment is stored in `$DEVENV_STATE/venv` and is activated automatically every time you enter the shell.
If the Python interpreter changes (for example, after updating `version`), the virtual environment is recreated.

### Installing packages from requirements

If your project uses a [requirements file](https://pip.pypa.io/en/stable/reference/requirements-file-format/), you can point devenv to it.
Packages are installed with pip when the shell starts:

```nix
{
  languages.python = {
    enable = true;
    venv = {
      enable = true;
      requirements = ./requirements.txt;
      # Or write requirements inline:
      # requirements = ''
      #   requests
      #   flask>=3.0
      # '';
    };
  };
}
```

devenv tracks a checksum of your requirements and your Python interpreter, so packages are only reinstalled when something actually changes.

Set `venv.quiet = true` to suppress pip output during installation.

<a id="section-3"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/languages/rust.md)

## Getting started

Enable Rust support in your `devenv.nix`:

```nix
{
  languages.rust.enable = true;
}
```

This will provide a complete Rust development environment with `rustc`, `cargo`, `clippy`, `rustfmt`, and `rust-analyzer`.

<a id="section-4"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/languages/javascript.md)

### languages.javascript.enable



Whether to enable tools for JavaScript development.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/javascript.nix](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/javascript.nix)

<a id="section-5"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/languages/go.md)

### languages.go.enable



Whether to enable tools for Go development.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/go.nix](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/go.nix)

<a id="section-6"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/services/postgres.md)

### services.postgres.enable



Whether to enable Add PostgreSQL process.
.



*Type:*
boolean



*Default:*

```nix
false
```



*Example:*

```nix
true
```

*Declared by:*
 - [https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/services/postgres.nix](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/services/postgres.nix)


<a id="selected-options"></a>

## Selected option records

Minimal enablement examples (choose those needed by the project):

```nix
{ ... }: {
  languages.python.enable = true;
  languages.javascript.enable = true;
  languages.rust.enable = true;
  languages.go.enable = true;
  services.postgres.enable = true;
}
```

[Committed upstream data](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/data/options.json). Rendered from this artifact, not rebuilt. Foreign declaration links retain their origin and may move independently.

- [`env`](#option-1)
- [`packages`](#option-2)
- [`enterShell`](#option-3)
- [`enterTest`](#option-4)
- [`scripts.<name>.exec`](#option-5)
- [`tasks.<name>.exec`](#option-6)
- [`tasks.<name>.before`](#option-7)
- [`tasks.<name>.after`](#option-8)
- [`tasks.<name>.status`](#option-9)
- [`processes.<name>.exec`](#option-10)
- [`languages.python.enable`](#option-11)
- [`languages.python.venv.enable`](#option-12)
- [`languages.javascript.enable`](#option-13)
- [`languages.javascript.npm.enable`](#option-14)
- [`languages.rust.enable`](#option-15)
- [`languages.go.enable`](#option-16)
- [`services.postgres.enable`](#option-17)

<a id="option-1"></a>

### `env`

Environment variables to be exposed inside the developer environment.

Type: `open submodule of lazy attribute set of anything`

Default:

```nix
{ }
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/top-level.nix)


<a id="option-2"></a>

### `packages`

A list of packages to expose inside the developer environment. Search available packages using ``devenv search NAME``.

Type: `list of package`

Default:

```nix
[ ]
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/top-level.nix)


<a id="option-3"></a>

### `enterShell`

Bash code to execute when entering the shell.

Type: `strings concatenated with "\n"`

Default:

```nix
""
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/top-level.nix)


<a id="option-4"></a>

### `enterTest`

Bash code to execute to run the test.

Type: `strings concatenated with "\n"`

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/tests.nix)


<a id="option-5"></a>

### `scripts.<name>.exec`

Shell code to execute when the script is run, or path to a script file.

Type: `string or absolute path`

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/scripts.nix)


<a id="option-6"></a>

### `tasks.<name>.exec`

Command to execute the task.

Type: `null or string`

Default:

```nix
null
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/tasks.nix)


<a id="option-7"></a>

### `tasks.<name>.before`

List of tasks that depend on this task completing first.

Here's a helpful mnemonic to remember: This task runs *before* these tasks.

You can append a suffix to control dependency behavior:
- `task@started` - the dependent waits for this task to begin execution
- `task` or `task@ready` - the dependent waits for this task to be ready/healthy (default for processes, processes only)
- `task@succeeded` - the dependent waits for this task to exit successfully (default for tasks, tasks only)
- `task@completed` - the dependent waits for this task to finish (soft dependency)

Type: `list of string`

Default:

```nix
[ ]
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/tasks.nix)


<a id="option-8"></a>

### `tasks.<name>.after`

List of tasks that must complete before this task runs.

Here's a helpful mnemonic to remember: This task runs *after* these tasks.

You can append a suffix to control dependency behavior:
- `task@started` - wait for task to begin execution
- `task` or `task@ready` - wait for task to be ready/healthy (default for processes, processes only)
- `task@succeeded` - wait for task to exit successfully (default for tasks, tasks only)
- `task@completed` - wait for task to finish, regardless of exit code (soft dependency)

Example: `after = [ "pnpm:install@completed" ];` allows this task to run
even if pnpm:install fails.

Type: `list of string`

Default:

```nix
[ ]
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/tasks.nix)


<a id="option-9"></a>

### `tasks.<name>.status`

Check if the command should be ran

Type: `null or string`

Default:

```nix
null
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/tasks.nix)


<a id="option-10"></a>

### `processes.<name>.exec`

Bash code to run the process.

Type: `string`

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/processes.nix)


<a id="option-11"></a>

### `languages.python.enable`

Whether to enable tools for Python development.

Type: `boolean`

Default:

```nix
false
```

Example:

```nix
true
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/python)


<a id="option-12"></a>

### `languages.python.venv.enable`

Whether to enable Python virtual environment.

Type: `boolean`

Default:

```nix
false
```

Example:

```nix
true
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/python)


<a id="option-13"></a>

### `languages.javascript.enable`

Whether to enable tools for JavaScript development.

Type: `boolean`

Default:

```nix
false
```

Example:

```nix
true
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/javascript.nix)


<a id="option-14"></a>

### `languages.javascript.npm.enable`

Whether to enable install npm.

Type: `boolean`

Default:

```nix
false
```

Example:

```nix
true
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/javascript.nix)


<a id="option-15"></a>

### `languages.rust.enable`

Whether to enable tools for Rust development.

Type: `boolean`

Default:

```nix
false
```

Example:

```nix
true
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/rust.nix)


<a id="option-16"></a>

### `languages.go.enable`

Whether to enable tools for Go development.

Type: `boolean`

Default:

```nix
false
```

Example:

```nix
true
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/languages/go.nix)


<a id="option-17"></a>

### `services.postgres.enable`

Whether to enable Add PostgreSQL process.
.

Type: `boolean`

Default:

```nix
false
```

Example:

```nix
true
```

[Declaration](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/src/modules/services/postgres.nix)
