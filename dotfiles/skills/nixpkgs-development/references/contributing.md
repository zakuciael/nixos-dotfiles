# Contributing

Nixpkgs master snapshot `4593931c855e7cf2ab412b659dd2841030f753df`; development series 26.11.

Modified excerpts from the Nixpkgs contributors; see [COPYING](../COPYING). Source citations are pinned; public manual links may move.

- [Overview](#contributing-overview)
- [How to create pull requests](#contributing-create-pull-requests)
- [How to review pull requests](#contributing-review-pull-requests)
- [Branch conventions](#contributing-branch-conventions)
- [Commit conventions](#contributing-commit-conventions)
- [File naming and organisation](#contributing-file-naming)
- [Formatting](#contributing-formatting)
- [Quick Start to Adding a Package](#pkgs-readme-quick-start)
- [Commit conventions](#pkgs-readme-commit-conventions)
- [Package naming](#pkgs-readme-package-naming)
- [Versioning](#pkgs-readme-versioning)
- [Patches](#pkgs-readme-patches)
- [Automatic package updates](#pkgs-readme-automatic-updates)
- [Name-based package directories](#by-name-directories)


<a id="contributing-overview"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md)

## Overview

This file contains general contributing information.
More specific information about individual parts of Nixpkgs can be found here:
- [`doc`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/README.md): Sources and infrastructure for the [Nixpkgs manual](https://nixos.org/manual/nixpkgs/stable/)
- [`lib`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/README.md): Sources and documentation of the [library functions](https://nixos.org/manual/nixpkgs/stable/#chap-functions)
- [`maintainers`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/maintainers/README.md): Nixpkgs maintainer and team listings, maintainer scripts
- [`nixos`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/README.md): Implementation of [NixOS](https://nixos.org/manual/nixos/stable/)
- [`pkgs`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md): Package and [builder](https://nixos.org/manual/nixpkgs/stable/#part-builders) definitions


<a id="contributing-create-pull-requests"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md)

## How to create pull requests

This section describes how changes can be proposed with a pull request (PR).

> [!Note]
> Be aware that contributing implies licensing those contributions under the terms of [COPYING](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/COPYING), an MIT-like license.

0. Set up a local version of Nixpkgs to work with:
   1. [Fork](https://docs.github.com/en/get-started/quickstart/fork-a-repo#forking-a-repository) the [Nixpkgs repository](https://github.com/nixos/nixpkgs).
   1. [Clone the forked repository](https://docs.github.com/en/get-started/quickstart/fork-a-repo#cloning-your-forked-repository) into a local `nixpkgs` directory.
   1. [Configure the upstream Nixpkgs repository](https://docs.github.com/en/get-started/quickstart/fork-a-repo#configuring-git-to-sync-your-fork-with-the-upstream-repository).

1. Select the appropriate [base branch](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-branches#working-with-branches) for the change, as [described here](#contributing-branch-conventions).
   If in doubt, use `master`.
   This can be changed later by [rebasing](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#rebasing-between-branches-ie-from-master-to-staging).

2. Create a new Git branch, ideally such that:
   - The name of the branch hints at your change, e.g. `update-hello`.
   - The branch contains the most recent base branch.

   We'll assume the base branch `master` here.

   ```bash
   # Make sure you have the latest changes from upstream Nixpkgs
   git fetch upstream

   # Create and switch to a new branch, based on the base branch in Nixpkgs
   git switch --create update-hello upstream/master
   ```

   To avoid potentially having to download and build many derivations, you can base on a specific [Git commit](https://www.git-scm.com/docs/gitglossary#def_commit) instead:
   - The commit of the latest `nixpkgs-unstable` channel, available [here](https://channels.nixos.org/nixpkgs-unstable/git-revision).
   - The commit of a local Nixpkgs downloaded using [nix-channel](https://nixos.org/manual/nix/stable/command-ref/nix-channel), available using `nix-instantiate --eval --expr '(import <nixpkgs/lib>).trivial.revisionWithDefault null'`
   - If you're using NixOS, the commit of your NixOS installation, available with `nixos-version --revision`.

   You can use this commit instead of `upstream/master` in the above command:
   ```bash
   # Here, b9c03fbb is an example commit from nixpkgs-unstable
   git switch --create update-hello b9c03fbb
   ```

3. Make your changes in the local Nixpkgs repository and:
   - Adhere to both the [general code conventions](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#code-conventions), and the relevant [specific code conventions](#contributing-overview).
   - Test the changes.
   - If necessary, document the changes.

   See the [overview section](#contributing-overview) for more specific information.

4. Commit your changes using `git commit`.
   Make sure to adhere to the [commit conventions](#contributing-commit-conventions).

   Repeat the steps 3-4 as many times as necessary.
   Advance to the next step once all the commits make sense together.
   You can view your commits with `git log`.

5. Push your commits to your fork of Nixpkgs:
   ```
   git push --set-upstream origin HEAD
   ```

   The above command will output a link to directly do the next step:
   ```
   remote: Create a pull request for 'update-hello' on GitHub by visiting:
   remote:      https://github.com/myUser/nixpkgs/pull/new/update-hello
   ```

6. [Create a pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request#creating-the-pull-request) from the new branch in your Nixpkgs fork to the upstream Nixpkgs repository.
   Use the branch from step 1 as the PR's base branch.
   Go through the [pull request template](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#pull-request-template).

7. Respond to review comments and potentially to CI failures and merge conflicts by updating the PR.
   Always keep it in a mergeable state.

   The non-technical side of this process is covered in [I opened a PR, how do I get it merged?](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#i-opened-a-pr-how-do-i-get-it-merged).

   The [ofborg](https://github.com/NixOS/ofborg) CI system will perform checks to ensure code quality.
   You can see the results at the bottom of the PR.
   See [the ofborg Readme](https://github.com/NixOS/ofborg#readme) for more details.

   - To add new commits, repeat steps 3-4 and push the result:
     ```
     git push
     ```

   - To change existing commits, [rewrite the Git history](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History).
     Useful Git commands for this are `git commit --patch --amend` and `git rebase --interactive`.
     With a rewritten history you need to force-push the commits:
     ```
     git push --force-with-lease
     ```

   - If there are merge conflicts, you will have to [rebase the branch](https://git-scm.com/book/en/v2/Git-Branching-Rebasing) onto the current **base branch**.
     Sometimes this can be done [on GitHub directly](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/keeping-your-pull-request-in-sync-with-the-base-branch#updating-your-pull-request-branch).
     To rebase locally:
     ```
     git fetch upstream
     git rebase upstream/master
     git push --force-with-lease
     ```

     Use the base branch from step 1 instead of `upstream/master`.

   - If you need to change the base branch, [rebase](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#rebasing-between-branches-ie-from-master-to-staging).

8. If your PR is merged and [acceptable for releases](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#changes-acceptable-for-releases), you may [backport](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#how-to-backport-pull-requests) it.

### Pull request template

The pull request template helps to determine which steps have been taken so far.
Details not covered by the title and links to existing related issues should go at the top.

When a PR is created, it will be pre-populated with some checkboxes.

#### Tested using sandboxing

When sandbox builds are enabled, Nix will set up an isolated environment for each build process.
It is used to remove further hidden dependencies set by the build environment, to improve reproducibility.
This includes access to the network during the build outside of `fetch*` functions and files outside the Nix store.
Depending on the operating system, access to other resources is blocked as well; see [sandbox](https://nixos.org/manual/nix/stable/command-ref/conf-file#conf-sandbox) in the Nix manual for details.

Please test builds with sandboxing enabled, because it is also used in [Hydra](https://nixos.org/hydra).

If you are on Linux, sandboxing is enabled by default.
On other platforms, sandboxing is disabled by default due to a small performance hit on each build.

Please enable sandboxing **before** building the package by adding the following to `/etc/nix/nix.conf`:

  ```ini
  sandbox = true
  ```

#### Built on platform(s)

Many Nix packages are designed to run on multiple platforms.
As such, it’s important to let the maintainer know which platforms you have tested on.
It’s not always practical to test all platforms, and it’s not required for a pull request to be merged.
Only check the platforms you tested the build on in this section.

#### Tested via one or more NixOS test(s) if existing and applicable for the change (look inside nixos/tests)

Packages with automated tests are likely merged quicker, because they don’t require as much manual testing.
If there are existing tests for the package, they should be run.
NixOS tests can only be run on linux.
For more details on writing and running tests, see the [section in the NixOS manual](https://nixos.org/nixos/manual/index.html#sec-nixos-tests).

#### Tested compilation of all pkgs that depend on this change using `nixpkgs-review`

If you are modifying a package, you can use `nixpkgs-review` to make sure all packages that depend on the updated package still build.
It can work on uncommitted changes with the `wip` option or on a specific pull request.

Review changes from pull request number 12345:

```ShellSession
nix-shell -p nixpkgs-review --run "nixpkgs-review pr 12345"
```

Alternatively, with flakes (and analogously for the other commands below):

```ShellSession
nix run nixpkgs#nixpkgs-review -- pr 12345
```

Review uncommitted changes:

```ShellSession
nix-shell -p nixpkgs-review --run "nixpkgs-review wip"
```

Review changes from the last commit:

```ShellSession
nix-shell -p nixpkgs-review --run "nixpkgs-review rev HEAD"
```

#### Tested execution of all binary files (usually in `./result/bin/`)

It's important to test a modified package's executables.
Look into `./result/bin` and run all files in there, or at a minimum, the main executable.
For example, if you make a change to `texlive`, you probably would only check the binaries associated with the change you made, rather than testing all of them.

#### Meets Nixpkgs contribution standards

The last two checkboxes are about whether it fits the guidelines in this `CONTRIBUTING.md` file.
This document details our standards for commit messages, reviews, licensing of contributions, etc...
Everyone should read and understand these standards before submitting a pull request.

### Rebasing between branches (i.e. from `master` to `staging`)

Sometimes, changes must be rebased between branches.
One example is, if the number of rebuilds caused is too large for the original target branch.

In the following example, the current `feature` branch is based on `master`, and we rebase it to have the PR target `staging`.
We rebase on the _merge base_ between `master` and `staging` to avoid too many local rebuilds.


```console
# Rebase your commits onto the common merge base
git rebase --onto upstream/staging... upstream/master
# Force push your changes
git push origin feature --force-with-lease
```

The syntax `upstream/staging...` is equivalent to `upstream/staging...HEAD` and stands for the merge base between `upstream/staging` and `HEAD` (hence between `upstream/staging` and `upstream/master`).

Then use the *Edit* button in the upper right corner of the GitHub PR, and switch the base branch from `master` to `staging`.
*After* the PR has been retargeted, a final rebase onto the target branch might be needed to resolve merge conflicts.

```console
# Rebase onto target branch
git rebase upstream/staging
# Review and fixup possible conflicts
git status
# Force push your changes
git push origin feature --force-with-lease
```


<a id="contributing-review-pull-requests"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md)

## How to review pull requests

The Nixpkgs project receives a high number of pull requests.
Anyone may review and approve PRs and it is an important contribution to the project.

The high change rate makes any PR that remains open for too long subject to merge conflicts.
To avoid extra work, reviewing PRs timely and being responsive is key.
GitHub provides sort filters to see the [most recently updated](https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+is%3Aopen+sort%3Aupdated-desc) pull requests.
We highly encourage looking at [this list of ready to merge, unreviewed pull requests](https://github.com/NixOS/nixpkgs/pulls?q=is%3Apr+is%3Aopen+review%3Anone+status%3Asuccess+no%3Aproject+no%3Aassignee+no%3Amilestone).

Controversial changes can lead to controversial opinions, but it is important to respect every community member and their work.
Always be nice and polite.

GitHub provides reactions for quick feedback to pull requests or comments.
The thumb-down reaction should be used with care and, if possible, accompanied with explanation for the submitter to improve their contribution.

When doing a review:
- Aim to drive the proposal to a timely conclusion.
- Focus on the proposed changes and keep the scope narrow.
- Help the contributor prioritise their efforts towards getting their change merged.

If you find anything related that could be improved but is not immediately required for acceptance, consider:
- Implementing the changes yourself in a follow-up pull request,
- Tracking your idea in an issue,
- Offering to review a follow-up pull request,
- Making concrete [suggestions](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/reviewing-changes-in-pull-requests/incorporating-feedback-in-your-pull-request) in the same pull request.

For example, follow-up changes could involve refactoring code in the affected files.

But please remember not to make such additional considerations a blocker, and communicate that to the contributor, for example by following the [conventional comments](https://conventionalcomments.org) pattern.
If the related change is essential for the contribution at hand, make clear why you think it is important to address that first.

Pull request reviews should include a list of what has been reviewed in a comment, so other reviewers and mergers can know the state of the review.

All the review templates provided are generic examples.
Their usage is optional and the reviewer is free to adapt them.

To get more information about how to review specific parts of Nixpkgs, refer to the documents linked to in the [overview section](#contributing-overview).

If a pull request contains documentation changes that might require feedback from the documentation team, ping [@NixOS/documentation-team](https://github.com/orgs/nixos/teams/documentation-team) on the pull request.

If you have enough knowledge and experience in a topic and would like to be a long-term reviewer for related submissions, please contact the current reviewers for that topic.
The main reviewers for a topic can be hard to find as there is no list, but checking past pull requests or git-blaming the code can give some hints.


<a id="contributing-branch-conventions"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md)

## Branch conventions
<!-- This section is relevant to both contributors and reviewers -->

Most changes should go to `master`, but sometimes other branches should be used instead.
Use the following decision process to figure out the right branch:

Is the change [acceptable for releases](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#changes-acceptable-for-releases) and do you wish to have the change in the release?
- No: Use the `master` branch, do not backport the pull request.
- Yes: Can the change be implemented the same way on the `master` and release branches?
  For example, a package's major version might differ between the `master` and release branches, such that separate security patches are required.
  - Yes: Use the `master` branch and [backport the pull request](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#how-to-backport-pull-requests).
  - No: Create separate pull requests to the `master` and `release-YY.MM` branches.

If the change causes a [mass rebuild](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#changes-causing-mass-rebuilds), use the `staging` branch instead:
- Mass rebuilds to `master` should go to `staging` instead.
- Mass rebuilds to `release-YY.MM` should go to `staging-YY.MM` instead.

See [this section](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#staging) for how such changes propagate between the branches.

### Changes acceptable for releases

Only changes to _supported_ releases may be accepted.
The oldest supported release (`YYMM`) can be found using
```
nix-instantiate --eval -A lib.trivial.oldestSupportedRelease
```

The release branches should generally only receive backwards-compatible changes, both for the Nix expressions and derivations.
Here are some examples of changes that are okay to backport:
- ✔️ New packages, modules and functions
- ✔️ Security fixes
- ✔️ Package version updates
  - ✔️ Patch versions with fixes
  - ✔️ Minor versions with new functionality, but no breaking changes

In addition, major package version updates with breaking changes are also acceptable for:
- ✔️ Services that would fail without up-to-date client software, such as `spotify`, `steam`, and `discord`
- ✔️ Security critical applications, such as `firefox` and `chromium`

### Changes causing mass rebuilds

Which changes cause mass rebuilds is not formally defined.
In order to help the decision, CI automatically assigns [`rebuild` labels](https://github.com/NixOS/nixpkgs/labels?q=rebuild) to pull requests based on the number of packages they cause rebuilds for.
As a rule of thumb, if the number of rebuilds is **500 or more**, consider targeting the `staging` branch instead of `master`; if the number is **1000 or more**, the pull request causes a mass rebuild, and should target the `staging` branch.
See [previously merged pull requests to the staging branches](https://github.com/NixOS/nixpkgs/issues?q=base%3Astaging+-base%3Astaging-next+is%3Amerged) to get a sense for what changes are considered mass rebuilds.

Please note that changes to the Linux kernel are an exception to this rule.
These PRs go to `staging-nixos`, see [the next section for more context](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#changes-rebuilding-all-nixos-tests).

### Changes rebuilding all NixOS tests

Changes causing a rebuild of all NixOS tests get a special [`10.rebuild-nixos-tests`](https://github.com/NixOS/nixpkgs/issues?q=state%3Aopen%20label%3A10.rebuild-nixos-tests) label.
These changes pose a significant impact on the build infrastructure.

Hence, these PRs should either target a `staging`-branch or `staging-nixos`-branch, provided one of following conditions applies:

* The label `10.rebuild-nixos-tests` is set, or
* The PR is a change affecting the Linux kernel.

The branch gets merged whenever mainline kernel updates or critical security fixes land on the branch.
This usually happens on a weekly basis.

Backports are not handled by such a branch.
The relevant PRs from this branch must be backported manually.


<a id="contributing-commit-conventions"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md)

## Commit conventions

- Create one commit for each logical unit.

- If you have commits `pkg-name: oh, forgot to insert whitespace`: squash commits in this case.
  Use `git rebase -i`.
  See [Squashing Commits](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History#_squashing) for additional information.

- For consistency, there should not be a period at the end of the commit message's summary line (the first line of the commit message).

- When adding yourself to `maintainer-list.nix`, make a separate commit with the message `maintainers: add <handle>`.
  Add the commit before those making changes to the package or module.
  See [Nixpkgs Maintainers](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/maintainers/README.md) for details.

- Make sure you read about any commit conventions specific to the area you're touching.
  See:
  - [Commit conventions](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/README.md#commit-conventions) for changes to `doc`, the Nixpkgs manual.
  - [Commit conventions](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/README.md#commit-conventions) for changes to `lib`.
  - [Commit conventions](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/nixos/README.md#commit-conventions) for changes to `nixos`.
  - [Commit conventions](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md#commit-conventions) for changes to `pkgs`.

### Writing good commit messages

It's important to include relevant information in the *commit message*, so others can later understand *why* a change was made.
While this potentially can be understood by reading code, PR discussion or upstream changes, doing so often requires a lot of work.

Simple package version updates need to include the attribute name, old and new versions, as well as a reference to the release notes or changelog.
Package upgrades with more extensive changes require more verbose commit messages.


<a id="contributing-file-naming"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md)

### File naming and organisation

Names of files and directories should be in lowercase, with dashes between words — kebab case, not camel case.
For instance, it should be `all-packages.nix`, not `allPackages.nix` or `AllPackages.nix`.


<a id="contributing-formatting"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md)

### Formatting

CI [enforces](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/.github/workflows/lint.yml) all Nix files to be formatted using the [official Nix formatter](https://github.com/NixOS/nixfmt).

You can ensure this locally using either of these commands:
```
nix fmt
nix develop --command treefmt
nix-shell --run treefmt
```

If you're starting your editor in `nix-shell` or `nix develop`, you can also set it up to automatically run `treefmt` on save.

If you have any problems with formatting, please ping the [formatting team](https://nixos.org/community/teams/formatting/) via [@NixOS/nix-formatting](https://github.com/orgs/NixOS/teams/nix-formatting).


<a id="pkgs-readme-quick-start"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md)

## Quick Start to Adding a Package

We welcome new contributors of new packages to Nixpkgs, arguably the greatest software database known.
However, each new package comes with a cost for the maintainers, Continuous Integration, caching servers and users downloading Nixpkgs.

Before adding a new package, please consider the following questions:

* Is the package ready for general use?
  We don't want to include projects that are too immature or are going to be abandoned immediately.
  In case of doubt, check with upstream.
* Does the project have a clear license statement?
  Remember that software is unfree by default (all rights reserved), and merely providing access to the source code does not imply its redistribution.
  In case of doubt, ask upstream.
* How realistic is it that it will be used by other people?
  It's good that nixpkgs caters to various niches, but if it's a niche of 5 people it's probably too small.
  A good estimate is checking upstream issues and pull requests, or other software repositories.
    * Library packages should have at least one dependent.
      If possible, that dependent should be packaged in the same PR the library is added in, as a sanity check.
      If it is not possible to package the dependent, a minimal test program should be added to `passthru.tests`.
* Is the software actively maintained upstream?
  Especially packages that are security-critical, rely on fast-moving dependencies, or affect data integrity should see regular maintenance.
* Are you willing to maintain the package?
  You should care enough about the package to be willing to keep it up and running for at least one complete Nixpkgs' release life-cycle.
  * In case you are not able to maintain the package you wrote, you can seek someone to fill that role, effectively adopting the package.

If any of these questions' answer is no, then you should probably not add the package.

Special care has to be taken with security-critical software components.
Because entries in the Nix store are inert and do nothing by themselves, packages should be considered by their intended use, e.g. when used together with a NixOS module.

* Any package that immediately would need to be tagged with `meta.knownVulnerabilities` is unlikely to be fit for nixpkgs.
* Any package depending on a known-vulnerable library should be considered carefully.
* Packages typically used with untrusted data should have a maintained and responsible upstream.
  For example:
  * Any package which does not follow upstream security policies should be considered vulnerable.
    In particular, packages that vendor or fork web engines like Blink, Gecko or Webkit need to keep up with the frequent updates of those projects.
  * Any security-critical fast-moving package such as Chrome or Firefox (or their forks) must have at least one committer among the maintainers, who actively reviews, merges and backports updates.
    This ensures no critical fixes are delayed unnecessarily, endangering unsuspecting users.
  * Services which typically work on web traffic are working on untrusted input.
  * Data (such as archives or rich documents) commonly shared over untrusted channels (e.g. email) is untrusted.
* Applications in the Unix authentication stack such as PAM/D-Bus modules or SUID binaries should be considered carefully, and should have a maintained and responsible upstream.
* Encryption libraries should have a maintained and responsible upstream.
* Security-critical components that are part of larger packages should be unvendored (=use the nixpkgs package as dependency, instead of vendored and pinned sources).
* A "responsible upstream" includes various aspects, such as:
  * channels to disclose security concerns
  * being responsive to security concerns, providing fixes or workarounds
  * transparent public disclosure of security issues when they are found or fixed
  * These aspects are sometimes hard to verify, in which case an upstream that is not known to be irresponsible should be considered as responsible.
* Source-available software should be built from source where possible.
  Binary blobs risk supply chain attacks and vendored outdated libraries.

This section describes a general framework of understanding and exceptions might apply.

Luckily it's pretty easy to maintain your own package set with Nix, which can then be added to the [Nix User Repository](https://github.com/nix-community/nur) project or included in [search.nixos.org's list of indexed 3rd-party flakes](https://github.com/NixOS/nixos-search/blob/main/flakes/manual.toml)

---

Now that this is out of the way.
To add a package to Nixpkgs:

1. Checkout the Nixpkgs source tree:

   ```ShellSession
   $ git clone https://github.com/NixOS/nixpkgs
   $ cd nixpkgs
   ```

2. Create a package directory `pkgs/by-name/so/some-package` where `some-package` is the package name and `so` is the lowercased 2-letter prefix of the package name:

   ```ShellSession
   $ mkdir -p pkgs/by-name/so/some-package
   ```

   For more detailed information, see [here](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/README.md).

3. Create a `package.nix` file in the package directory, containing a Nix expression — a piece of code that describes how to build the package.
   In this case, it should be a _function_ that is called with the package dependencies as arguments, and returns a build of the package in the Nix store.

   ```ShellSession
   $ emacs pkgs/by-name/so/some-package/package.nix
   $ git add pkgs/by-name/so/some-package/package.nix
   ```

   If the package is written in a language other than C, you should use [the corresponding language framework](https://nixos.org/manual/nixpkgs/stable/#chap-language-support).

   You can have a look at the existing Nix expressions under `pkgs/` to see how it’s done, some of which are also using the [category hierarchy](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md#category-hierarchy).
   Here are some good ones:

   - GNU Hello: [`pkgs/by-name/he/hello/package.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/he/hello/package.nix).
     Trivial package, which specifies some `meta` attributes which is good practice.

   - GNU cpio: [`pkgs/by-name/cp/cpio/package.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/cp/cpio/package.nix).
     Also a simple package.
     The generic builder in `stdenv` does everything for you.
     It has no dependencies beyond `stdenv`.

   - GNU Multiple Precision arithmetic library (GMP): [`pkgs/development/libraries/gmp`](https://github.com/NixOS/nixpkgs/tree/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/development/libraries/gmp).
     Also done by the generic builder, but has a dependency on `m4`.

   - Pan, a GTK-based newsreader: [`pkgs/by-name/pa/pan/package.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/pa/pan/package.nix).
     Has an optional dependency on `gspell`, which is only built if `spellCheck` is `true`.

   - Apache HTTPD: [`pkgs/servers/http/apache-httpd/2.4.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/servers/http/apache-httpd/2.4.nix).
     A bunch of optional features, variable substitutions in the configure flags, a post-install hook, and miscellaneous hackery.

   - buildMozillaMach: [`pkgs/build-support/build-mozilla-mach/default.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/build-support/build-mozilla-mach/default.nix).
     A reusable build function for Firefox, Thunderbird and Librewolf.

   - JDiskReport, a Java utility: [`pkgs/by-name/jd/jdiskreport/package.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/jd/jdiskreport/package.nix).
     Nixpkgs doesn’t have a decent `stdenv` for Java yet so this is pretty ad-hoc.

   - XML::Simple, a Perl module: [`pkgs/top-level/perl-packages.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/top-level/perl-packages.nix) (search for the `XMLSimple` attribute).
     Most Perl modules are so simple to build that they are defined directly in `perl-packages.nix`; no need to make a separate file for them.

   - Discord Game SDK: [`pkgs/by-name/di/discord-gamesdk/package.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/di/discord-gamesdk/package.nix).
     Shows how binary-only packages can be supported.
     In particular, the `autoPatchelfHook` is used to set the RUNPATH and ELF interpreter of the executables so that the right libraries are found at runtime.

   Some notes:

   - Add yourself as the maintainer of the package.

     - If this is your first time contributing (welcome!), [add yourself to the maintainers list](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/maintainers/README.md#how-to-become-a-maintainer) in a separate commit.

   - All other [`meta`](https://nixos.org/manual/nixpkgs/stable/#chap-meta) attributes are optional, but it’s still a good idea to provide at least the `description`, `homepage` and [`license`](https://nixos.org/manual/nixpkgs/stable/#sec-meta-license).

   - The exact syntax and semantics of the Nix expression language, including the built-in functions, can be found in the [Nix language reference](https://nixos.org/manual/nix/stable/language/).

5. To test whether the package builds, run the following command from the root of the nixpkgs source tree:

   ```ShellSession
   $ nix-build -A some-package
   ```

   where `some-package` should be the package name.
   You may want to add the flag `-K` to keep the temporary build directory in case something fails.
   If the build succeeds, a symlink `./result` to the package in the Nix store is created.

6. If you want to install the package into your profile (optional), do

   ```ShellSession
   $ nix-env -f . -iA libfoo
   ```

7. Optionally commit the new package and open a pull request [to nixpkgs](https://github.com/NixOS/nixpkgs/pulls), or use [the Patches category](https://discourse.nixos.org/t/about-the-patches-category/477) on Discourse for sending a patch without a GitHub account.


<a id="pkgs-readme-commit-conventions"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md)

## Commit conventions

- Make sure you read about the [commit conventions](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#commit-conventions) common to Nixpkgs as a whole.

- Format the commit messages in the following way:

  ```
  (pkg-name): (from -> to | init at version | refactor | etc)

  (Motivation for change. Link to release notes. Additional information.)
  ```

  Examples:

  * nginx: init at 2.0.1
  * qt6Packages.qtdeclarative: fix build
  * firefox: 54.0.1 -> 55.0

    https://www.mozilla.org/en-US/firefox/55.0/releasenotes/

(using "→" instead of "->" is also accepted)

For package sets with multiple versions, such as `perlPackages` (aliased to
`perl5Packages`) and `python3Packages` (aliased to `python313Packages` at the
time of writing), please use the unversioned attribute in your commit message
unless the change is specific to one version.

Using the `(pkg-name):` prefix is important beyond just being a convention: it queues automatic builds by CI.
More sophisticated prefixes are also possible:

| Message                                                                  | Automatic Builds                                           |
|--------------------------------------------------------------------------|------------------------------------------------------------|
| `vim: 1.0.0 -> 2.0.0`                                                    | `vim`                                                      |
| `vagrant: fix dependencies for version 2.0.2`                            | `vagrant`                                                  |
| `python3Packages.requests: 1.0.0 -> 2.0.0`                               | `python3Packages.requests`                                 |
| `python3Packagess.{numpy,scipy}: fix build`                              | `python3Packages.numpy` , `python3Packages.scipy`          |

When opening a PR with multiple commits, CI creates a single build job for all detected packages.
If `passthru.tests` attributes are available, these will be built as well.

If the title of the _PR_ begins with `WIP:` or contains `[WIP]` anywhere, its packages are not built automatically.
Other than that, PR titles have meaning only for humans.
It is recommended to keep the PR title in sync with the commit title, to make it easier to find.
For PRs with multiple commits, the PR title should be a general summary of these commits.

> [!NOTE]
> Marking a PR as a draft does not prevent automatic builds.


<a id="pkgs-readme-package-naming"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md)

## Package naming

In Nixpkgs, there are generally three different names associated with a package:

- The `pname` attribute of the derivation.
  This is what most users see, in particular when using `nix-env`.

- The attribute name used for the package in the [`pkgs/by-name` structure](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/README.md) or in [`all-packages.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/top-level/all-packages.nix), and when passing it as a dependency in recipes.

- The filename for (the directory containing) the Nix expression.

Most of the time, these are the same.
For instance, the package `e2fsprogs` has a `pname` attribute `"e2fsprogs"`, is bound to the attribute name `e2fsprogs` in `all-packages.nix`, and the Nix expression is in `pkgs/os-specific/linux/e2fsprogs/default.nix`.

Follow these guidelines:

- For the `pname` attribute:

  - It _should_ be identical to the upstream package name.

  - It _must not_ contain uppercase letters.

    Example: Use `"mplayer"` instead of `"MPlayer"`

- For the package attribute name:

  - It _must_ be a valid identifier in Nix.

  - If the `pname` starts with a digit, the attribute name _should_ be prefixed with an underscore.
    Otherwise the attribute name _should not_ be prefixed with an underscore.

    Example: The corresponding attribute name for `0ad` should be `_0ad`.

  - New attribute names _should_ be the same as the value in `pname`.

    Hyphenated names _should not_ be converted to [snake case](https://en.wikipedia.org/wiki/Snake_case) or [camel case](https://en.wikipedia.org/wiki/Camel_case).
    This was done historically, but is not necessary any more.
    [The Nix language allows dashes in identifiers since 2012](https://github.com/NixOS/nix/commit/95c74eae269b2b9e4bc514581b5caa1d80b54acc).

  - If there are multiple versions of a package, this _should_ be reflected in the attribute names in `all-packages.nix`.

    Example: `json-c_0_9` and `json-c_0_11`

    If there is an obvious “default” version, make an extra attribute.

    Example: `json-c = json-c_0_9;`

    See also [versioning](#pkgs-readme-versioning).


<a id="pkgs-readme-versioning"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md)

## Versioning

These are the guidelines for the `version` attribute of a package:

- It _must_ start with a digit.
  This is required for backwards-compatibility with [how `nix-env` parses derivation names](https://nix.dev/manual/nix/latest/command-ref/nix-env#selectors).

  Example: `"0.3.1rc2"` or `"0-unstable-1970-01-01"`

- If a package is a commit from a repository without a version assigned, then the `version` attribute _should_ be the latest upstream version preceding that commit, followed by `-unstable-` and the date of the (fetched) commit.
  The date _must_ be in `"YYYY-MM-DD"` format.

  Example: Given a project had its latest releases `2.2` in November 2021 and `3.0` in January 2022, a commit authored on March 15, 2022 for an upcoming bugfix release `2.2.1` would have `version = "2.2-unstable-2022-03-15"`.

- If a project has no suitable preceding releases - e.g., no versions at all, or an incompatible versioning or tagging scheme - then the latest upstream version in the above schema should be `0`.

  Example: Given a project that has no tags or released versions at all, or applies versionless tags like `latest` or `YYYY-MM-DD-Build`, a commit authored on March 15, 2022 would have `version = "0-unstable-2022-03-15"`.

Because every version of a package in Nixpkgs creates a potential maintenance burden, old versions of a package should not be kept unless there is a good reason to do so.
For instance, Nixpkgs contains several versions of GCC because other packages don’t build with the latest version of GCC.
Other examples are having both the latest stable and latest pre-release version of a package, or to keep several major releases of an application that differ significantly in functionality.

If there is only one version of a package, its Nix expression should be named (e.g) `pkgs/by-name/xy/xyz/package.nix`.
If there are multiple versions, this should be reflected in the attribute name.
If you wish to share code between the Nix expressions of each version, you cannot rely upon `pkgs/by-name`'s automatic attribute creation, and must create the attributes yourself in `all-packages.nix`.
See also [`pkgs/by-name/README.md`'s section on this topic](https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/README.md#recommendation-for-new-packages-with-multiple-versions).


<a id="pkgs-readme-patches"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md)

## Patches

Sometimes, changes are needed to the source to allow building a derivation in nixpkgs, or to get earlier access to an upstream fix or improvement.
When using the `patches` parameter to `mkDerivation`, make sure the patch name clearly describes the reason for the patch, or add a comment.

> [!Note]
> The version of the package does not need to be changed just because a patch is applied.
> Declarative package installations don't depend on the version, while imperative `nix-env` installations can use [`upgrade --eq/leq/--always`](https://nix.dev/manual/nix/2.25/command-ref/nix-env/upgrade#flags).
>
> See [Versioning](#pkgs-readme-versioning) for details on package versioning.

The following describes two ways to include the patch.
Regardless of how the patch is included, you _must_ ensure its purpose is clear and obvious.
This enables other maintainers to more easily determine when old patches are no longer required.
Typically, you can improve clarity with carefully considered filenames, attribute names, and/or comments; these should explain the patch's _intention_.
Additionally, it may sometimes be helpful to clarify _how_ it resolves the issue.
For example: _"fix gcc14 build by adding missing include"_.

### Fetching patches

In the interest of keeping our maintenance burden and the size of Nixpkgs to a minimum, patches already merged upstream or published elsewhere _should_ be retrieved using `fetchpatch2`:

```nix
{
  patches = [
    (fetchpatch2 {
      name = "make-no-atomics-a-soft-failure.patch";
      url = "https://github.com/boostorg/math/commit/7d482f6ebc356e6ec455ccb5f51a23971bf6ce5b.patch?full_index=1";
      hash = "sha256-9Goa0NTUdSOs1Vm+FnkoSFhw0o8ZLNOw6cLUqCVnF5Y=";
    })
  ];
}
```

> [!Warning]
> If the patch file contains short commit hashes, use `fetchpatch` instead of `fetchpatch2` ([tracking issue](https://github.com/NixOS/nixpkgs/issues/257446)).
> This is the case if the patch contains a line similar to `index 0c97fcc35..f533e464a 100644`.
> Depending on the patch source it is possible to expand the commit hash, in which case using `fetchpatch2` is acceptable (e.g. GitHub supports appending `?full_index=1` to the URL, as seen above).

If a patch is available online but does not cleanly apply, it can be modified in some fixed ways by using additional optional arguments for `fetchpatch2`.
Check [the `fetchpatch` reference](https://nixos.org/manual/nixpkgs/unstable/#fetchpatch) for details.

When adding patches in this manner you should be reasonably sure that the used URL is stable.
Patches referencing open pull requests will change when the PR is updated and code forges (such as GitHub) usually garbage collect commits that are no longer reachable due to rebases/amends.

### Vendoring patches

In the following cases, a `.patch` file _should_ be added to Nixpkgs repository, instead of retrieved:

- solves problems unique to packaging in Nixpkgs
- cannot be fetched easily
- has a high chance to disappear in the future due to unstable or unreliable URLs

The latter avoids link rot when the upstream abandons, squashes or rebases their change, in which case the commit may get garbage-collected.

```nix
{ patches = [ ./0001-add-missing-include.patch ]; }
```

If you do need to create this sort of patch file, one way to do so is with git:

1. Move to the root directory of the source code you're patching.

    ```ShellSession
    $ cd the/program/source
    ```

2. If a git repository is not already present, create one and stage all of the source files.

    ```ShellSession
    $ git init
    $ git add -A
    ```

3. Edit some files to make whatever changes need to be included in the patch.

4. Use git to create a diff, and pipe the output to a patch file:

    ```ShellSession
    $ git diff -a > nixpkgs/pkgs/the/package/0001-changes.patch
    ```


<a id="pkgs-readme-automatic-updates"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md)

## Automatic package updates

The [community bot `r-ryantm`](https://nix-community.org/update-bot/), periodically tries to update all packages in Nixpkgs.
It runs the program [`nixpkgs-update`](https://nix-community.github.io/nixpkgs-update/) which finds new versions of packages, modifies the relevant files, and opens a Nixpkgs PR.
`nixpkgs-update` has a specific set of capabilities of finding new versions for a package, and updating Nix files accordingly (see their [FAQ](https://nix-community.github.io/nixpkgs-update/nixpkgs-maintainer-faq/)).
However, setting a `passthru.updateScript` for a package, sets an explicit update procedure for `nixpkgs-update`, that can find the latest version more reliably than `nixpkgs-update`, and modify the necessary files more correctly.


<a id="by-name-directories"></a>

[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/README.md)

# Name-based package directories

The structure of this directory maps almost directly to top-level package attributes.
Add new top-level packages to Nixpkgs using this mechanism [whenever possible](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/README.md#limitations).

Packages found in the name-based structure are automatically included, without needing to be added to `all-packages.nix`. However if the implicit attribute defaults need to be changed for a package, this [must still be declared in `all-packages.nix`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/README.md#changing-implicit-attribute-defaults).

## Example

The top-level package `pkgs.some-package` may be declared by setting up this file structure:

```
pkgs
└── by-name
   ├── so
   ┊  ├── some-package
      ┊  └── package.nix

```

Where `some-package` is the attribute name corresponding to the package, and `so` is the lowercase 2-letter prefix of the attribute name.

The `package.nix` may look like this:

```nix
# A function taking an attribute set as an argument
{
  # Get access to top-level attributes for use as dependencies
  lib,
  stdenv,
  libbar,

  # Make this derivation configurable using `.override { enableBar = true }`
  enableBar ? false,
}:

# The return value must be a derivation
stdenv.mkDerivation {
  # ...
  buildInputs = lib.optional enableBar libbar;
}
```

You can also split up the package definition into more files in the same directory if necessary.

Once defined, the package can be built from the Nixpkgs root directory using:
```
nix-build -A some-package
```

See the [general package conventions](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md#conventions) for more information on package definitions.

### Changing implicit attribute defaults

The above expression is called using these arguments by default:
```nix
{
  lib = pkgs.lib;
  stdenv = pkgs.stdenv;
  libbar = pkgs.libbar;
}
```

But the package might need `pkgs.libbar_2` instead.
While the `libbar` argument could explicitly be overridden in `all-packages.nix` with `libbar_2`, this would hide important information about this package from its interface.
The fact that the package requires a certain version of `libbar` to work should not be hidden in a separate place.
It is preferable to use `libbar_2` as an argument name instead.

This approach also has the benefit that, if the expectation of the package changes to require a different version of `libbar`, a downstream user with an override of this argument will receive an error.
This is comparable to a merge conflict in git: It's much better to be forced to explicitly address the conflict instead of silently keeping the override - which might lead to a different problem that is likely much harder to debug.

## Manual migration guidelines

Most packages are still defined in `all-packages.nix` and the [category hierarchy](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md#category-hierarchy).
Since it would take a lot of contributor and reviewer time to migrate all packages manually,
an [automated migration is planned](https://github.com/NixOS/nixpkgs/pull/211832),
though it is expected to still take some time to get done.
If you're interested in helping out with this effort,
please see [this ticket](https://github.com/NixOS/nixpkgs-vet/issues/56).

Since [only PRs to packages in `pkgs/by-name` can be automatically merged](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/CONTRIBUTING.md#how-to-merge-pull-requests-yourself),
if package maintainers would like to use this feature, they are welcome to migrate their packages to `pkgs/by-name`.
To lessen PR traffic, they're encouraged to also perform some more general maintenance on the package in the same PR,
though this is not required and must not be expected.

Note that `callPackage` definitions in `all-packages.nix` with custom arguments should not be removed.
That is a backwards-incompatible change because it changes the `.override` interface.
Such packages may still be moved to `pkgs/by-name` however, in order to avoid the slightly superficial choice of directory / category in which the `default.nix` file was placed, but please keep the definition in `all-packages.nix` using `callPackage`.
See also [changing implicit attribute defaults](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/by-name/README.md#changing-implicit-attribute-defaults).

Definitions like the following however, _can_ be transitioned:

```nix
# all-packages.nix
{
  fooWithBaz = foo.override { bar = baz; };
}
```

```nix
# turned into pkgs/by-name/fo/fooWithBaz/package.nix with:
{ foo, baz }:

foo.override { bar = baz; }
```

## Limitations

There are some limitations as to which packages can be defined using this structure:

- Only packages defined using `pkgs.callPackage`.
  This excludes packages defined using `pkgs.python3Packages.callPackage ...`.

  Instead:
  - Either change the package definition to work with `pkgs.callPackage`.
  - Or use the [category hierarchy](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/pkgs/README.md#category-hierarchy).

- Only top-level packages.
  This excludes packages for other package sets like `pkgs.pythonPackages.*`.

  Refer to the definition and documentation of the respective package set to figure out how such packages can be declared.

## Validation

CI performs [certain checks](https://github.com/NixOS/nixpkgs-vet?tab=readme-ov-file#validity-checks) on the `pkgs/by-name` structure.
This is done using the [`nixpkgs-vet` tool](https://github.com/NixOS/nixpkgs-vet).

You can locally emulate the CI check using

```
$ ./ci/nixpkgs-vet.sh master
```

## Recommendation for new packages with multiple versions

These checks of the `pkgs/by-name` structure can cause problems in combination:
1. New top-level packages using `callPackage` must be defined via `pkgs/by-name`.
2. Packages in `pkgs/by-name` cannot refer to files outside their own directory.

This means that outside `pkgs/by-name`, multiple already-present top-level packages can refer to some common file.
If you open a PR to another instance of such a package, CI will fail check 1,
but if you try to move the package to `pkgs/by-name`, it will fail check 2.

This is often the case for packages with multiple versions, such as

```nix
{
  foo_1 = callPackage ../tools/foo/1.nix { };
  foo_2 = callPackage ../tools/foo/2.nix { };
}
```

The best way to resolve this is to not use `callPackage` directly, such that check 1 doesn't trigger.
This can be done by using `inherit` on a local package set:
```nix
{
  inherit
    ({
      foo_1 = callPackage ../tools/foo/1.nix { };
      foo_2 = callPackage ../tools/foo/2.nix { };
    })
    foo_1
    foo_2
    ;
}
```

While this may seem pointless, this can in fact help with future package set refactorings,
because it establishes a clear connection between related attributes.

### Further possible refactorings

This is not required, but the above solution also allows refactoring the definitions into a separate file:

```nix
{ inherit (import ../tools/foo pkgs) foo_1 foo_2; }
```

```nix
# pkgs/tools/foo/default.nix
pkgs: {
  foo_1 = callPackage ./1.nix { };
  foo_2 = callPackage ./2.nix { };
}
```

Alternatively using [`callPackages`](https://nixos.org/manual/nixpkgs/unstable/#function-library-lib.customisation.callPackagesWith)
if `callPackage` isn't used underneath and you want the same `.override` arguments for all attributes:

```nix
{ inherit (callPackages ../tools/foo { }) foo_1 foo_2; }
```

```nix
# pkgs/tools/foo/default.nix
{ stdenv }:
{
  foo_1 = stdenv.mkDerivation {
    # ...
  };
  foo_2 = stdenv.mkDerivation {
    # ...
  };
}
```

### Exposing the package set

This is not required, but the above solution also allows exposing the package set as an attribute:

```nix
{
  foo-versions = import ../tools/foo pkgs;
  # Or using callPackages
  # foo-versions = callPackages ../tools/foo { };

  inherit (foo-versions) foo_1 foo_2;
}
```
