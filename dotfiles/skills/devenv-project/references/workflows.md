# Workflows

devenv v2.3.1; upstream revision `2418e1b43797c44de5166176622c8d8fa0149871`.

Modified excerpts from the devenv contributors; see [LICENSE](../LICENSE). Source citations are pinned; devenv.sh links follow the moving public site.

- [auto-activation.mdx: Setup](#section-1)
- [auto-activation.mdx: Trusting a project](#section-2)
- [auto-activation.mdx: Revoking trust](#section-3)
- [auto-activation.mdx: How it works](#section-4)
- [auto-activation.mdx: Comparison with direnv](#section-5)
- [integrations/direnv.mdx: Configure shell activation](#section-6)
- [integrations/direnv.mdx: Approving and loading the shell](#section-7)
- [scripts.md: Scripts](#section-8)
- [scripts.md: Aliases & args](#section-9)
- [scripts.md: Runtime packages](#section-10)
- [tasks.md: Defining tasks](#section-11)
- [tasks.md: Dependencies between tasks](#section-12)
- [tasks.md: enterShell / enterTest](#section-13)
- [processes.md: Basic Example](#section-14)
- [processes.md: Using Pre-built Services](#section-15)
- [tests.md: Tests](#section-16)
- [tests.md: Writing your first test](#section-17)
- [git-hooks.md: Git Hooks](#section-18)
- [git-hooks.md: Managing the `.pre-commit-config.yaml` file](#section-19)

<a id="section-1"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/auto-activation.mdx)

**Tip: New in version 2.1**


[Read more about auto activation in the v2.1 release post](https://devenv.sh/blog/2026/05/07/devenv-21-nix-with-zsh-fish-and-nushell-via-libghostty/)

**End tip.**


## Setup


### Bash

Add one line to your shell configuration file:


File: `~/.bashrc`

```bash
eval "$(devenv hook bash)"
```

### Zsh

Add one line to your shell configuration file:


File: `~/.zshrc`

```bash
eval "$(devenv hook zsh)"
```

### Fish

Usually nothing to do — devenv installed via Nix ships a snippet that fish loads
automatically. If it doesn't load for you, add this instead:


File: `~/.config/fish/config.fish`

```fish
devenv hook fish | source
```

### Nushell

Usually nothing to do — devenv installed via Nix ships a snippet that nu loads
automatically. If it doesn't load for you, add this instead:

Run once, in Nu:

```nu
mkdir ($nu.default-config-dir | path join autoload)
devenv hook nu | save --force ($nu.default-config-dir | path join autoload/devenv-hook.nu)
```

### Passing arguments to `devenv shell`


**Tip: New in version 2.3**


Place arguments for the auto-activated `devenv shell` after `--`. For example,
to disable the TUI in shells started by the Fish hook without changing other
`devenv` commands:


File: `~/.config/fish/config.fish`

```fish
devenv hook fish -- --no-tui | source
```

The same separator works in every supported shell:


File: `~/.bashrc`

```bash
eval "$(devenv hook bash -- --no-tui)"
```


**End tip.**

<a id="section-2"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/auto-activation.mdx)

**Tip: New in version 2.1**


[Read more about auto activation in the v2.1 release post](https://devenv.sh/blog/2026/05/07/devenv-21-nix-with-zsh-fish-and-nushell-via-libghostty/)

**End tip.**


## Trusting a project

Before a project can auto activate, you need to explicitly trust it. This is a security measure that prevents untrusted projects from modifying your shell.

Navigate to the project directory and run:

```sh
$ cd ~/myproject
$ devenv allow
devenv: allowed /home/user/myproject
```

To activate one or more profiles whenever the project is entered, pass them
when allowing it:

```shellsession
$ devenv --profile backend --profile observability allow
devenv: allowed /home/user/myproject with profile backend, observability
```

The selected profiles also apply to subsequent devenv commands in the project.
An explicit `--profile` takes priority. Run plain `devenv allow` again to clear
the saved profile selection without revoking trust.

When you `cd` into the directory next time, devenv will automatically start a shell:

```sh
$ cd ~/myproject
(devenv) $
```

<a id="section-3"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/auto-activation.mdx)

**Tip: New in version 2.1**


[Read more about auto activation in the v2.1 release post](https://devenv.sh/blog/2026/05/07/devenv-21-nix-with-zsh-fish-and-nushell-via-libghostty/)

**End tip.**


## Revoking trust

To stop a project from auto activating:

```sh
$ cd ~/myproject
$ devenv revoke
devenv: revoked /home/user/myproject
```

<a id="section-4"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/auto-activation.mdx)

**Tip: New in version 2.1**


[Read more about auto activation in the v2.1 release post](https://devenv.sh/blog/2026/05/07/devenv-21-nix-with-zsh-fish-and-nushell-via-libghostty/)

**End tip.**


## How it works

The hook runs on every directory change and:

2. Checks the trust database to verify the project was allowed.
3. If trusted, runs `devenv shell` in a subshell for that project.

If a project has not been trusted yet, you will see a message asking you to run `devenv allow`:

```
devenv: /home/user/myproject is not allowed. Run 'devenv allow' to trust this directory.
```


**Note**

The hook detects projects by looking for a `devenv.nix` file.
Before version 2.2, it looked for `devenv.yaml` instead, so projects with only `devenv.nix` were not auto-detected.

**End note.**

<a id="section-5"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/auto-activation.mdx)

**Tip: New in version 2.1**


[Read more about auto activation in the v2.1 release post](https://devenv.sh/blog/2026/05/07/devenv-21-nix-with-zsh-fish-and-nushell-via-libghostty/)

**End tip.**


## Comparison with direnv

| Feature | `devenv hook` | [direnv](https://devenv.sh/integrations/direnv/) |
|---|---|---|
| External dependencies | None | Requires direnv |
| Setup | One line in shell config | direnv install + `.envrc` per project |
| Trust granularity | Per project directory | Per `.envrc` file |
| Environment application | Spawns a subshell | Modifies current shell in place |
| Unloading on exit | Subshell exits automatically | direnv unloads variables |

Use `devenv hook` for a simple, dependency free setup. Use [direnv](https://devenv.sh/integrations/direnv/) if you prefer in place environment modification without a subshell.

<a id="section-6"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/integrations/direnv.mdx)

## Configure shell activation

Create an `.envrc` file in your project directory with the following content:


### v1.4+


File: `.envrc`

```bash
#!/usr/bin/env bash

eval "$(devenv direnvrc)"

# You can pass flags to the devenv command
# For example: use devenv --impure --option services.postgres.enable:bool true
use devenv
```

### v1.3 and older


File: `.envrc`

```bash
#!/usr/bin/env bash

source_url "https://raw.githubusercontent.com/cachix/devenv/82c0147677e510b247d8b9165c54f73d32dfd899/direnvrc" "sha256-7u4iDd1nZpxL4tCzmPG0dQgC5V+/44Ba+tHkPob1v2k="

use devenv
```


This file configures direnv to use devenv for shell activation.


**Note**

`devenv init` does not create a `.envrc` file by default.

**End note.**




**Tip: New in version 2.2**

Use `devenv init --include-envrc` to include an `.envrc` file. On earlier versions, create it manually using the snippet above.

**End tip.**

<a id="section-7"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/integrations/direnv.mdx)

## Approving and loading the shell

Once the `.envrc` file is in place, you'll see a warning in your shell:

```
direnv: error ~/myproject/.envrc is blocked. Run `direnv allow` to approve its content
```

Run `direnv allow` to approve the `.envrc` file. This step is a security measure to ensure you've reviewed the content before allowing it to modify your shell environment.

After approval, direnv will automatically load and unload the devenv environment whenever you enter and exit the project directory:

```sh
$ cd /home/user/myproject/
direnv: loading ~/myproject/.envrc
Building shell ...
Entering shell ...

(devenv) $
```

<a id="section-8"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/scripts.md)

# Scripts

Most projects out there have a bunch of shell scripts lying around.

Questions arise as to where to define scripts and how to provide the tooling to make sure they work for all developers.

A simple example defining `silly-example` script:


File: `devenv.nix`

```nix
{ pkgs, ... }:

{
  packages = [ pkgs.curl pkgs.jq ]; # See [Packages](/packages/) for an explanation.

  scripts.silly-example.exec = ''
    curl "https://httpbin.org/get?$1" | jq '.args'
  '';
}
```


Since scripts are exposed when we enter the environment, we can rely on ``packages`` executables being available.

```sh
$ devenv shell
Building shell ...
Entering shell ...

(devenv) $ silly-example foo=1
{
  "foo": "1"
}
```

<a id="section-9"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/scripts.md)

### Aliases & args
Here's an example that shows how to define an alias & forward arguments:
```
scripts.foo.exec = ''
  npx @foo/cli "$@";
'';
```

<a id="section-10"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/scripts.md)

## Runtime packages

Sometimes you need packages available only when a specific script runs, without adding them to the global environment. You can specify runtime packages using the `packages` attribute:


File: `devenv.nix`

```nix
{ pkgs, ... }:

{
  scripts.analyze-json = {
    exec = ''
      # Both curl and jq are available when this script runs
      curl "https://httpbin.org/get?$1" | jq '.args'
    '';
    packages = [ pkgs.curl pkgs.jq ];
    description = "Fetch and analyze JSON";
  };
}
```

The `packages` attribute ensures these tools are available in the script's PATH without polluting the global development environment.

<a id="section-11"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/tasks.md)

**Added in version 1.2.**

## Defining tasks


File: `devenv.nix`

```nix
{ pkgs, ... }:

{
  tasks."myapp:hello" = {
    exec = ''echo "Hello, world!"'';
  };
}
```

```sh
$ devenv tasks run myapp:hello
Running tasks     myapp:hello
Succeeded         myapp:hello         9ms
1 Succeeded                           10.14ms
```

**Added in version 1.7.**

You can also run all tasks in a namespace by providing just the namespace prefix:

```sh
$ devenv tasks run myapp
Running tasks     myapp:hello myapp:build myapp:test
Succeeded         myapp:hello           9ms
Succeeded         myapp:build         120ms
Succeeded         myapp:test          350ms
3 Succeeded                           479.14ms
```

<a id="section-12"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/tasks.md)

**Added in version 1.2.**

## Dependencies between tasks

Tasks form a dependency graph (a DAG). Declare an edge between two tasks with `before` or `after`:

- `after = [ "other" ]` — run this task *after* `other` (`other` is a dependency, "upstream").
- `before = [ "other" ]` — run this task *before* `other` (`other` is "downstream" and depends on this one).

Processes are tasks too (see [Processes as tasks](https://devenv.sh/tasks/#processes-as-tasks)), so the same `before`/`after` edges connect tasks and processes interchangeably — see [process dependencies](https://devenv.sh/processes/#dependencies) for process-focused examples.

`before` and `after` describe the same edge from opposite ends, so you can declare a dependency from whichever side is more convenient. These are equivalent:


File: `devenv.nix`

```nix
{
  # declared from the dependent task
  tasks."myapp:build".after = [ "myapp:generate" ];

  # ...is the same edge as declaring it from the dependency
  tasks."myapp:generate".before = [ "myapp:build" ];
}
```

### Dependency states


**Tip: New in version 2.0**


**End tip.**



A dependency waits for its target to reach a particular state before it is considered satisfied. Append an `@` suffix to choose the state explicitly:

| Suffix | Satisfied when | Failure propagates? |
| --- | --- | --- |
| `@started` | the target has begun executing | yes |
| `@ready` | a process passes its [readiness probe](https://devenv.sh/processes/#ready-probes); for oneshot tasks this means success | yes |
| `@succeeded` | the target exits with code `0` (or is skipped) | yes |
| `@completed` | the target finishes, regardless of exit code | no (soft dependency) |

When no suffix is given the default is `@ready` for processes and `@succeeded` for oneshot tasks.

A common use is running a setup task once a service is ready:


File: `devenv.nix`

```nix
{
  tasks."myapp:configure" = {
    exec = "create-buckets";
    after = [ "devenv:processes:garage@ready" ];
  };
}
```

<a id="section-13"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/tasks.md)

**Added in version 1.2.**

## enterShell / enterTest

`devenv:enterShell` and `devenv:enterTest` are built-in lifecycle events that run setup tasks at specific points:

- **`devenv:enterShell`** runs before the shell is entered (`devenv shell`) and before processes start (`devenv up`).
- **`devenv:enterTest`** runs before tests execute (`devenv test`).
  It depends on `devenv:enterShell`, so all shell setup tasks run first automatically.

To hook into these events, use `before` to declare that your task should run before the event completes:


File: `devenv.nix`

```nix
{ pkgs, lib, config, ... }:

{
  tasks = {
    "bash:hello" = {
      exec = "echo 'Hello world from bash!'";
      before = [ "devenv:enterShell" ];
    };

    "myapp:test-setup" = {
      exec = "echo 'Preparing test fixtures...'";
      before = [ "devenv:enterTest" ];
    };
  };
}
```

```sh
$ devenv shell
...
Running tasks     devenv:enterShell
Succeeded         devenv:git-hooks:install  25ms
Succeeded         bash:hello                 9ms
Succeeded         devenv:enterShell         13ms
3 Succeeded                                 28.14ms
```

Many devenv modules automatically hook into these events.
For example, enabling git hooks registers `devenv:git-hooks:install` as a dependency of `devenv:enterShell`.

<a id="section-14"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/processes.md)

## Basic Example


File: `devenv.nix`

```nix
{ pkgs, ... }:

{
  processes = {
    silly-example.exec = "while true; do echo hello && sleep 1; done";
    ping.exec = "ping localhost";
    server = {
      exec = "python -m http.server";
      cwd = "./public";
    };
  };
}
```

To start the processes, run:

```sh
$ devenv up
```

To stop processes started in the background:

```sh
$ devenv down
```


**Tip: New in devenv 2.2**


`devenv down` is a shorthand for `devenv processes down`.

**End tip.**



With the native process manager, wait for all processes to become ready (useful in CI):

```sh
$ devenv processes wait --timeout 120
```

The default timeout is 120 seconds.

<a id="section-15"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/processes.md)

## Using Pre-built Services

Devenv provides many pre-configured services with proper process management. See the [Services documentation](https://devenv.sh/services/) for available services like:

- [PostgreSQL](https://devenv.sh/services/postgres/)
- [Redis](https://devenv.sh/services/redis/)
- [MySQL](https://devenv.sh/services/mysql/)
- [MongoDB](https://devenv.sh/services/mongodb/)
- [Elasticsearch](https://devenv.sh/services/elasticsearch/)

These services come with sensible defaults, health checks, and proper initialization scripts.

<a id="section-16"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/tests.md)

# Tests

Tests are a way to ensure that your development environment is working as expected.

Running `devenv test` will build your environment and run the tests defined in `enterTest`.

If you have [processes](https://devenv.sh/processes/) defined in your environment, they will be started and stopped for you.


**Tip: Consider using tasks for tests**

For more complex test setups with dependencies and better control, consider using [tasks with the `before` attribute](https://devenv.sh/tasks/#entershell--entertest). Tasks can be configured to run before `devenv:enterTest` and provide better parallelization and dependency management.

**End tip.**

<a id="section-17"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/tests.md)

## Writing your first test

A simple test would look like:


File: `devenv.nix`

```nix
{ pkgs, ... }: {
  packages = [ pkgs.ncdu ];

  enterTest = ''
    ncdu --version | grep "ncdu 2.2"
  '';
}
```

```sh
$ devenv test
✓ Building tests in 2.5s.
• Running tests ...
Setting up shell environment...
Running test...
ncdu 2.2
✓ Running tests in 4.7s.
✓ Tests passed. in 0.0s.
```

By default, the `enterTest` detects if `.test.sh` file exists and runs it.

<a id="section-18"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/git-hooks.md)

# Git Hooks

``devenv`` has first-class integration for [pre-commit](https://pre-commit.com/) via [git-hooks.nix](https://github.com/cachix/git-hooks.nix).
This integration _requires_ to have the `git-hooks` input the `devenv.yaml` file, as in [the inputs page](https://devenv.sh/inputs/).

If this is not already in the file, add it using `devenv inputs add git-hooks github:cachix/git-hooks.nix` or insert it manually:

File: `devenv.yml snippet`

```yaml
inputs:
  git-hooks:
    url: github:cachix/git-hooks.nix
```

<a id="section-19"></a>

[Upstream source](https://github.com/cachix/devenv/blob/2418e1b43797c44de5166176622c8d8fa0149871/docs/src/content/docs/git-hooks.md)

## Managing the `.pre-commit-config.yaml` file

The `.pre-commit-config.yaml` file is a symlink to an autogenerated file in your `devenv` Nix store.
It is not necessary to commit this file to your repository and it can safely be ignored.
This file name will be added to your `.gitignore` file by default when you run `devenv init`.
