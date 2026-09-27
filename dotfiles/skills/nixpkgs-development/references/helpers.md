# Helpers

Nixpkgs master snapshot `4593931c855e7cf2ab412b659dd2841030f753df`; development series 26.11.

Modified excerpts from the Nixpkgs contributors; see [COPYING](../COPYING). Source citations are pinned; public manual links may move.

- [Build helpers](#part-builders)
- [Caveats](#chap-pkgs-fetchers-caveats)
- [Updating source hashes](#sec-pkgs-fetchers-updating-source-hashes)
- [Obtaining hashes securely](#sec-pkgs-fetchers-secure-hashes)
- [`fetchurl`](#sec-pkgs-fetchers-fetchurl)
- [Inputs](#sec-pkgs-fetchers-fetchurl-inputs)
- [`fetchzip`](#sec-pkgs-fetchers-fetchzip)
- [Inputs](#sec-pkgs-fetchers-fetchzip-inputs)
- [`fetchFromGitHub`](#fetchfromgithub)
- [`runCommand` and `runCommandCC`](#trivial-builder-runCommand)
- [`writeText`](#trivial-builder-writeText)
- [`writeShellApplication`](#trivial-builder-writeShellApplication)
- [pkgs.mkShell](#sec-pkgs-mkShell)
- [`buildPythonPackage` function](#buildpythonpackage-function)
- [`buildPythonApplication` function](#buildpythonapplication-function)
- [buildNpmPackage](#javascript-buildNpmPackage)
- [Building Go modules with `buildGoModule`](#ssec-language-go)
- [`buildRustPackage`: Compiling Rust applications with Cargo](#compiling-rust-applications-with-cargo)


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers.md)


# Build helpers

<a id="part-builders"></a>

A build helper is a function that produces derivations.

**Warning**

This is not to be confused with the [`builder` argument of the Nix `derivation` primitive](https://nixos.org/manual/nix/unstable/language/derivations.html), which refers to the executable that produces the build result, or [remote builder](https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html), which refers to a remote machine that could run such an executable.

**End warning.**


Such a function is usually designed to abstract over a typical workflow for a given programming language or framework.
This allows declaring a build recipe by setting a limited number of options relevant to the particular use case instead of using the `derivation` function directly.

[`stdenv.mkDerivation`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv.md) (source section: Standard environment) is the most widely used build helper and serves as a basis for many others.
In addition, it offers various options to customize parts of the builds.

There is no uniform interface for build helpers.
[Trivial build helpers](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/trivial-build-helpers.chapter.md) (source section: Trivial build helpers) and [fetchers](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Fetchers) have various input types for convenience.
[Language- or framework-specific build helpers](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/index.md) (source section: Languages and frameworks) usually follow the style of `stdenv.mkDerivation`, which accepts an attribute set or a fixed-point function taking an attribute set.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


## Caveats

<a id="chap-pkgs-fetchers-caveats"></a>

Because Nixpkgs fetchers are fixed-output derivations, an [output hash](https://nixos.org/manual/nix/stable/language/advanced-attributes#adv-attr-outputHash) has to be specified, usually indirectly through a `hash` attribute.
This hash refers to the derivation output, which can be different from the remote source itself!

This has the following implications that you should be aware of:

- Use Nix (or Nix-aware) tooling to produce the output hash.

- When changing any fetcher parameters, always update the output hash.
  Use one of the methods from [Updating source hashes](helpers.md#sec-pkgs-fetchers-updating-source-hashes).
  Otherwise, existing store objects that match the output hash will be re-used rather than fetching new content.

**Note**

  A similar problem arises while testing changes to a fetcher's implementation.
  If the output of the derivation already exists in the Nix store, test failures can go undetected.
  The [`invalidateFetcherByDrvHash`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/testers.chapter.md) (source section: `invalidateFetcherByDrvHash`) function helps prevent reusing cached derivations.

**End note.**



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


## Updating source hashes

<a id="sec-pkgs-fetchers-updating-source-hashes"></a>

There are several ways to obtain the hash corresponding to a remote source.
Unless you understand how the fetcher you're using calculates the hash from the downloaded contents, you should use [the fake hash method](helpers.md#sec-pkgs-fetchers-updating-source-hashes-fakehash-method).

1. <a id="sec-pkgs-fetchers-updating-source-hashes-fakehash-method"></a> The fake hash method: In your package recipe, set the hash to one of

   - `""`
   - `lib.fakeHash`
   - `lib.fakeSha256`
   - `lib.fakeSha512`

   Attempt to build, extract the calculated hashes from error messages, and put them into the recipe.

**Warning**

   You must use one of these four fake hashes and not some arbitrarily-chosen hash.
   See [Obtaining hashes securely](helpers.md#sec-pkgs-fetchers-secure-hashes) for details.

**End warning.**


<a id="ex-fetchers-update-fod-hash"></a>

**Example**

   # Update source hash with the fake hash method

   Consider the following recipe that produces a plain file:

   ```nix
   { fetchurl }:
   fetchurl {
     url = "https://raw.githubusercontent.com/NixOS/nixpkgs/23.05/.version";
     hash = "sha256-ZHl1emidXVojm83LCVrwULpwIzKE/mYwfztVkvpruOM=";
   }
   ```

   A common mistake is to update a fetcher parameter, such as `url`, without updating the hash:

   ```nix
   { fetchurl }:
   fetchurl {
     url = "https://raw.githubusercontent.com/NixOS/nixpkgs/23.11/.version";
     hash = "sha256-ZHl1emidXVojm83LCVrwULpwIzKE/mYwfztVkvpruOM=";
   }
   ```

   **This will produce the same output as before!**
   Set the hash to an empty string:

   ```nix
   { fetchurl }:
   fetchurl {
     url = "https://raw.githubusercontent.com/NixOS/nixpkgs/23.11/.version";
     hash = "";
   }
   ```

   When building the package, use the error message to determine the correct hash:

   ```shell
   $ nix-build
   (some output removed for clarity)
   error: hash mismatch in fixed-output derivation '/nix/store/7yynn53jpc93l76z9zdjj4xdxgynawcw-version.drv':
           specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
               got:    sha256-BZqI7r0MNP29yGH5+yW2tjU9OOpOCEvwWKrWCv5CQ0I=
   error: build of '/nix/store/bqdjcw5ij5ymfbm41dq230chk9hdhqff-version.drv' failed
   ```

**End example.**


2. Prefetch the source with [`nix-prefetch-<type> <URL>`](https://search.nixos.org/packages?buckets={%22package_attr_set%22%3A[%22No%20package%20set%22]%2C%22package_license_set%22%3A[]%2C%22package_maintainers_set%22%3A[]%2C%22package_platforms%22%3A[]}&query=nix-prefetch), where `<type>` is one of

   - `url`
   - `git`
   - `hg`
   - `cvs`
   - `bzr`
   - `svn`
   - `darcs`
   - `pijul`

   The hash is printed to stdout.

3. Prefetch by package source (with `nix-prefetch-url '<nixpkgs>' -A <package>.src`, where `<package>` is package attribute name).
   The hash is printed to stdout.

   This works well when you've upgraded the existing package version and want to find out new hash, but is useless if the package can't be accessed by attribute or the package has multiple sources (`.srcs`, architecture-dependent sources, etc).

4. Upstream hash: use it when upstream provides `sha256` or `sha512`.
   Don't use it when upstream provides `md5`, compute `sha256` instead.

   A little nuance is that `nix-prefetch-*` tools produce hashes with the `nix32` encoding (a Nix-specific base32 adaptation), but upstream usually provides hexadecimal (`base16`) encoding.
   Fetchers understand both formats.
   Nixpkgs does not standardise on any one format.

   You can convert between hash formats with [`nix-hash`](https://nixos.org/manual/nix/stable/command-ref/nix-hash).

5. Extract the hash from a local source archive with `sha256sum`.
   Use `nix-prefetch-url file:///path/to/archive` if you want the custom Nix `base32` hash.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


## Obtaining hashes securely

<a id="sec-pkgs-fetchers-secure-hashes"></a>

It's always a good idea to avoid Man-in-the-Middle (MITM) attacks when downloading source contents.
Otherwise, you could unknowingly download malware instead of the intended source, and instead of the actual source hash, you'll end up using the hash of malware.
Here are security considerations for this scenario:

- `http://` URLs are not secure to prefetch hashes.

- Upstream hashes should be obtained via a secure protocol.

- `https://` URLs give you more protections when using `nix-prefetch-*` or for upstream hashes.

- `https://` URLs are secure when using the [fake hash method](helpers.md#sec-pkgs-fetchers-updating-source-hashes-fakehash-method) *only if* you use one of the listed fake hashes.
  If you use any other hash, the download will be exposed to MITM attacks even if you use HTTPS URLs.

  In more concrete terms, if you use any other hash, the [`--insecure` flag](https://curl.se/docs/manpage.html#-k) will be passed to the underlying call to `curl` when downloading content.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


## `fetchurl`

<a id="sec-pkgs-fetchers-fetchurl"></a>

`fetchurl` returns a [fixed-output derivation](https://nixos.org/manual/nix/stable/glossary.html#gloss-fixed-output-derivation) which downloads content from a given URL and stores the unaltered contents within the Nix store.

It uses [`curl(1)`](https://curl.se/docs/manpage.html) internally, and allows its behaviour to be modified by specifying a few attributes in the argument to `fetchurl` (see the documentation for attributes `curlOpts`, `curlOptsList`, and `netrcPhase`).

The resulting [store path](https://nixos.org/manual/nix/stable/store/store-path) is determined by the hash given to `fetchurl`, and also the `name` (or `pname` and `version`) values.

If neither `name` nor `pname` and `version` are specified when calling `fetchurl`, it will default to using the [basename](https://nixos.org/manual/nix/stable/language/builtins.html#builtins-baseNameOf) of `url` or the first element of `urls`.
If `pname` and `version` are specified, `fetchurl` will use those values and will ignore `name`, even if it is also specified.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


### Inputs

<a id="sec-pkgs-fetchers-fetchurl-inputs"></a>

`fetchurl` requires an attribute set with the following attributes:

`url` (String; _optional_)
Definition: The URL to download from.

**Note**

  Either `url` or `urls` must be specified, but not both.

**End note.**


  All URLs of the format [specified here](https://curl.se/docs/url-syntax.html#rfc-3986-plus) are supported.

  _Default value:_ `""`.

`urls` (List of String; _optional_)
Definition: A list of URLs, specifying download locations for the same content.
  Each URL will be tried in order until one of them succeeds with some content or all of them fail.
  See [Using `fetchurl` to download a file with multiple possible URLs](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Using `fetchurl` to download a file with multiple possible URLs) to understand how this attribute affects the behaviour of `fetchurl`.

**Note**

  Either `url` or `urls` must be specified, but not both.

**End note.**


  _Default value:_ `[]`.

`hash` (String; _optional_)
Definition: Hash of the derivation output of `fetchurl`, following the format for integrity metadata as defined by [SRI](https://www.w3.org/TR/SRI/).
  For more information, see [Caveats](helpers.md#chap-pkgs-fetchers-caveats).

**Note**

  It is recommended that you use the `hash` attribute instead of the other hash-specific attributes that exist for backwards compatibility.

  If `hash` is not specified, you must specify `outputHash` and `outputHashAlgo`, or one of `sha512`, `sha256`, or `sha1`.

**End note.**


  _Default value:_ `""`.

`outputHash` (String; _optional_)
Definition: Hash of the derivation output of `fetchurl` in the format expected by Nix.
  See [the documentation on the Nix manual](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-outputHash) for more information about its format.

**Note**

  It is recommended that you use the `hash` attribute instead.

  If `outputHash` is specified, you must also specify `outputHashAlgo`.

**End note.**


  _Default value:_ `""`.

`outputHashAlgo` (String; _optional_)
Definition: Algorithm used to generate the value specified in `outputHash`.
  See [the documentation on the Nix manual](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-outputHashAlgo) for more information about the values it supports.

**Note**

  It is recommended that you use the `hash` attribute instead.

  The value specified in `outputHashAlgo` will be ignored if `outputHash` isn't also specified.

**End note.**


  _Default value:_ `""`.

`sha1` (String; _optional_)
Definition: SHA-1 hash of the derivation output of `fetchurl` in the format expected by Nix.
  See [the documentation on the Nix manual](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-outputHash) for more information about its format.

**Note**

  It is recommended that you use the `hash` attribute instead.

**End note.**


  _Default value:_ `""`.

`sha256` (String; _optional_)
Definition: SHA-256 hash of the derivation output of `fetchurl` in the format expected by Nix.
  See [the documentation on the Nix manual](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-outputHash) for more information about its format.

**Note**

  It is recommended that you use the `hash` attribute instead.

**End note.**


  _Default value:_ `""`.

`sha512` (String; _optional_)
Definition: SHA-512 hash of the derivation output of `fetchurl` in the format expected by Nix.
  See [the documentation on the Nix manual](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-outputHash) for more information about its format.

**Note**

  It is recommended that you use the `hash` attribute instead.

**End note.**


  _Default value:_ `""`.

`name` (String; _optional_)
Definition: The symbolic name of the downloaded file when saved in the Nix store.
  See [the `fetchurl` overview](helpers.md#sec-pkgs-fetchers-fetchurl) for details on how the name of the file is decided.

  _Default value:_ `""`.

`pname` (String; _optional_)
Definition: A base name, which will be combined with `version` to form the symbolic name of the downloaded file when saved in the Nix store.
  See [the `fetchurl` overview](helpers.md#sec-pkgs-fetchers-fetchurl) for details on how the name of the file is decided.

**Note**

  If `pname` is specified, you must also specify `version`, otherwise `fetchurl` will ignore the value of `pname`.

**End note.**


  _Default value:_ `""`.

`version` (String; _optional_)
Definition: A version, which will be combined with `pname` to form the symbolic name of the downloaded file when saved in the Nix store.
  See [the `fetchurl` overview](helpers.md#sec-pkgs-fetchers-fetchurl) for details on how the name of the file is decided.

  _Default value:_ `""`.

`recursiveHash` (Boolean; _optional_) <a id="sec-pkgs-fetchers-fetchurl-inputs-recursiveHash"></a>
Definition: If set to `true`, will signal to Nix that the hash given to `fetchurl` was calculated using the `"recursive"` mode.
  See [the documentation on the Nix manual](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-outputHashMode) for more information about the existing modes.

  By default, `fetchurl` uses `"recursive"` mode when the `executable` attribute is set to `true`, so you don't need to specify `recursiveHash` in this case.

  _Default value:_ `false`.

`executable` (Boolean; _optional_)
Definition: If `true`, sets the executable bit on the downloaded file.

  _Default value_: `false`.

`downloadToTemp` (Boolean; _optional_) <a id="sec-pkgs-fetchers-fetchurl-inputs-downloadToTemp"></a>
Definition: If `true`, saves the downloaded file to a temporary location instead of the expected Nix store location.
  This is useful when used in conjunction with `postFetch` attribute, otherwise `fetchurl` will not produce any meaningful output.

  The location of the downloaded file will be set in the `$downloadedFile` variable, which should be used by the script in the `postFetch` attribute.
  See [Manipulating the content downloaded by `fetchurl`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Manipulating the content downloaded by `fetchurl`) to understand how to work with this attribute.

  _Default value:_ `false`.

`postFetch` (String; _optional_)
Definition: Script executed after the file has been downloaded successfully, and before `fetchurl` finishes running.
  Useful for post-processing, to check or transform the file in some way.
  See [Manipulating the content downloaded by `fetchurl`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Manipulating the content downloaded by `fetchurl`) to understand how to work with this attribute.

  _Default value:_ `""`.

`netrcPhase` (String or Null; _optional_)
Definition: Script executed to create a [`netrc(5)`](https://man.cx/netrc) file to be used with [`curl(1)`](https://curl.se/docs/manpage.html).
  The script should create the `netrc` file (note that it does not begin with a ".") in the directory it's currently running in (`$PWD`).

  The script is executed during the setup done by `fetchurl` before it runs any of its code to download the specified content.

**Note**

  If specified, `fetchurl` will automatically alter its invocation of [`curl(1)`](https://curl.se/docs/manpage.html) to use the `netrc` file, so you don't need to add anything to `curlOpts` or `curlOptsList`.

**End note.**


**Caution**

  Since `netrcPhase` needs to be specified in your source Nix code, any secrets that you put directly in it will be world-readable by design (both in your source code, and when the derivation gets created in the Nix store).

  If you want to avoid this behaviour, see the documentation of `netrcImpureEnvVars` for an alternative way of dealing with these secrets.

**End caution.**


  _Default value_: `null`.

`netrcImpureEnvVars` (List of String; _optional_)
Definition: If specified, `fetchurl` will add these environment variable names to the list of [impure environment variables](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-impureEnvVars), which will be passed from the environment of the calling user to the builder running the `fetchurl` code.

  This is useful when used with `netrcPhase` to hide any secrets that are used in it, because the script in `netrcPhase` only needs to reference the environment variables with the secrets in them instead.
  However, note that these are called _impure_ variables for a reason:
  the environment that starts the build needs to have these variables declared for everything to work properly, which means that additional setup is required outside what Nix controls.

  _Default value:_ `[]`.

`curlOpts` (String; _optional_)
Definition: If specified, this value will be appended to the invocation of [`curl(1)`](https://curl.se/docs/manpage.html) when downloading the URL(s) given to `fetchurl`.
  Multiple arguments can be separated by spaces normally, but values with whitespaces will be interpreted as multiple arguments (instead of a single value), even if the value is escaped.
  See `curlOptsList` for a way to pass values with whitespaces in them.

  _Default value:_ `""`.

`curlOptsList` (List of String; _optional_)
Definition: If specified, each element of this list will be passed as an argument to the invocation of [`curl(1)`](https://curl.se/docs/manpage.html) when downloading the URL(s) given to `fetchurl`.
  This allows passing values that contain spaces, with no escaping needed.

  _Default value:_ `[]`.

`showURLs` (Boolean; _optional_)
Definition: If set to `true`, this will stop `fetchurl` from downloading anything at all.
  Instead, it will output a list of all the URLs it would've used to download the content (after resolving `mirror://` URLs, for example).
  This is useful for debugging.

  _Default value:_ `false`.

`meta` (Attribute Set; _optional_)
Definition: Specifies any [meta-attributes](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md) (source section: Meta-attributes) for the derivation returned by `fetchurl`.

  _Default value:_ `{}`.

`passthru` (Attribute Set; _optional_)
Definition: Specifies any extra [`passthru`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/passthru.chapter.md) (source section: Passthru-attributes) attributes for the derivation returned by `fetchurl`.
  Note that `fetchurl` defines [`passthru` attributes of its own](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Passthru outputs).
  Attributes specified in `passthru` can override the default attributes returned by `fetchurl`.

  _Default value:_ `{}`.

`preferLocalBuild` (Boolean; _optional_)
Definition: This is the same attribute as [defined in the Nix manual](https://nixos.org/manual/nix/stable/language/advanced-attributes.html#adv-attr-preferLocalBuild).
  It is `true` by default because making a remote machine download the content just duplicates network traffic (since the local machine might download the results from the derivation anyway), but this could be useful in cases where network access is restricted on local machines.

  _Default value:_ `true`.

`nativeBuildInputs` (List of Attribute Set; _optional_)
Definition: Additional packages needed to download the content.
  This is useful if you need extra packages for `postFetch` or `netrcPhase`, for example.
  Has the same semantics as in [`nativeBuildInputs`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: `nativeBuildInputs`).
  See [Manipulating the content downloaded by `fetchurl`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Manipulating the content downloaded by `fetchurl`) to understand how this can be used with `postFetch`.

  _Default value:_ `[]`.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


## `fetchzip`

<a id="sec-pkgs-fetchers-fetchzip"></a>

Returns a [fixed-output derivation](https://nixos.org/manual/nix/stable/glossary.html#gloss-fixed-output-derivation) which downloads an archive from a given URL and decompresses it.

Despite its name, `fetchzip` is not limited to `.zip` files but can also be used with [various compressed tarball formats](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: Tar files) by default.
This can be extended by specifying additional attributes, see [Using `fetchzip` to decompress a `.rar` file](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Using `fetchzip` to decompress a `.rar` file) to understand how to do that.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


### Inputs

<a id="sec-pkgs-fetchers-fetchzip-inputs"></a>

`fetchzip` requires an attribute set, and most attributes are passed to the underlying call to [`fetchurl`](helpers.md#sec-pkgs-fetchers-fetchurl).

The attributes below are treated differently by `fetchzip` when compared to what `fetchurl` expects:

`name` (String; _optional_)
Definition: Works as defined in `fetchurl`, but has a different default value than `fetchurl`.

  _Default value:_ `"source"`.

`nativeBuildInputs` (List of Attribute Set; _optional_)
Definition: Works as defined in `fetchurl`, but it is also augmented by `fetchzip` to include packages to deal with additional archives (such as `.zip`).

  _Default value:_ `[]`.

`postFetch` (String; _optional_)
Definition: Works as defined in `fetchurl`, but it is also augmented with the code needed to make `fetchzip` work.

**Caution**

  It is only safe to modify files in `$out` in `postFetch`.
  Consult the implementation of `fetchzip` for anything more involved.

**End caution.**


  _Default value:_ `""`.

`stripRoot` (Boolean; _optional_)
Definition: If `true`, the decompressed contents are moved one level up the directory tree.

  This is useful for archives that decompress into a single directory which commonly includes some values that change with time, such as version numbers.
  When this is the case (and `stripRoot` is `true`), `fetchzip` will remove this directory and make the decompressed contents available in the top-level directory.

  [Using `fetchzip` to output contents directly](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md) (source section: Using `fetchzip` to output contents directly) shows what this attribute does.

  This attribute is **not** passed through to `fetchurl`.

  _Default value:_ `true`.

`extension` (String or Null; _optional_)
Definition: If set, the archive downloaded by `fetchzip` will be renamed to a filename with the extension specified in this attribute.

  This is useful when making `fetchzip` support additional types of archives, because the implementation may use the extension of an archive to determine whether they can decompress it.
  If the URL you're using to download the contents doesn't end with the extension associated with the archive, use this attribute to fix the filename of the archive.

  This attribute is **not** passed through to `fetchurl`.

  _Default value:_ `null`.

`recursiveHash` (Boolean; _optional_)
Definition: Works [as defined in `fetchurl`](helpers.md#sec-pkgs-fetchers-fetchurl-inputs-recursiveHash), but its default value is different than for `fetchurl`.

  _Default value:_ `true`.

`downloadToTemp` (Boolean; _optional_)
Definition: Works [as defined in `fetchurl`](helpers.md#sec-pkgs-fetchers-fetchurl-inputs-downloadToTemp), but its default value is different than for `fetchurl`.

  _Default value:_ `true`.

`extraPostFetch` **DEPRECATED**
Definition: This attribute is deprecated.
  Please use `postFetch` instead.

  This attribute is **not** passed through to `fetchurl`.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/fetchers.chapter.md)

**Tip**

`pkgs.fetchFrom*` helpers retrieve _snapshots_ of version-controlled sources, as opposed to the entire version history, which is more efficient.
`pkgs.fetchgit` by default also has the same behaviour, but can be changed through specific attributes given to it.

**End tip.**


## `fetchFromGitHub`

<a id="fetchfromgithub"></a>

`fetchFromGitHub` expects four arguments. `owner` is a string corresponding to the GitHub user or organization that controls this repository. `repo` corresponds to the name of the software repository. These are located at the top of every GitHub HTML page as `owner`/`repo`. `rev` corresponds to the Git commit hash or tag (e.g `v1.0`) that will be downloaded from Git. If you need to fetch a tag however, you should prefer to use the `tag` parameter which achieves this in a safer way with less boilerplate. Finally, `hash` corresponds to the hash of the extracted directory. Again, other hash algorithms are also available, but `hash` is currently preferred.

To use a different GitHub instance, use `githubBase` (defaults to `"github.com"`).

By default, `fetchFromGitHub` uses `fetchzip` to download GitHub's source archive for the specified revision.
However, `fetchFromGitHub` will automatically switch to using `fetchgit` in any of these cases:

- `forceFetchGit`, `leaveDotGit`, `deepClone`, `fetchLFS`, or `fetchSubmodules` are set to `true`
- `sparseCheckout` contains any entries (is a non-empty list)
- `rootDir` is set to a non-empty string

When `fetchgit` is used, refer to the `fetchgit` section for documentation of its available options.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/trivial-build-helpers.chapter.md)


## `runCommand` and `runCommandCC`

<a id="trivial-builder-runCommand"></a>

The function `runCommand` returns a derivation built using the specified command(s), in the `stdenvNoCC` environment.

`runCommandCC` is similar but uses the default compiler environment. To minimize dependencies, `runCommandCC`
should only be used when the build command needs a C compiler.

`runCommandLocal` is also similar to `runCommand`, but forces the derivation to be built locally.
See the note on [`runCommandWith`] about `runLocal`.


### Type

<a id="trivial-builder-runCommand-Type"></a>

```
runCommand      :: String -> AttrSet -> String -> Derivation
runCommandCC    :: String -> AttrSet -> String -> Derivation
runCommandLocal :: String -> AttrSet -> String -> Derivation
```

### Input

<a id="trivial-builder-runCommand-Input"></a>

While the type signature(s) differ from [`runCommandWith`], individual arguments with the same name will have the same type and meaning:

`name` (String)
Definition: The derivation's name

`derivationArgs` (Attribute set *or* [function from `finalAttrs`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/trivial-build-helpers.chapter.md) (source section: Arguments with finalAttrs))
Definition: Additional parameters passed to [`mkDerivation`]

`buildCommand` (String *or* [function from `finalAttrs`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/trivial-build-helpers.chapter.md) (source section: Arguments with finalAttrs))
Definition: The command(s) run to build the derivation.


<a id="ex-runcommand-simple"></a>

**Example**

# Invocation of `runCommand`

```nix
runCommand "my-example" { } ''
  echo My example command is running

  mkdir $out

  echo I can write data to the Nix store > $out/message

  echo I can also run basic commands like:

  echo ls
  ls

  echo whoami
  whoami

  echo date
  date
''
```

**End example.**


**Note**

`runCommand name derivationArgs buildCommand` is equivalent to
```nix
runCommandWith {
  inherit name derivationArgs;
  stdenv = stdenvNoCC;
} buildCommand
```

Likewise, `runCommandCC name derivationArgs buildCommand` is equivalent to
```nix
runCommandWith { inherit name derivationArgs; } buildCommand
```

**End note.**



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/trivial-build-helpers.chapter.md)

**Note**

Some of these functions will put the resulting files within a directory inside the [derivation output](https://nixos.org/manual/nix/stable/language/derivations#attr-outputs).
If you need to refer to the resulting files somewhere else in a Nix expression, append their path to the derivation's store path.

For example, if the file destination is a directory:

```nix
{
  my-file = writeTextFile {
    name = "my-file";
    text = ''
      Contents of File
    '';
    destination = "/share/my-file";
  };
}
```

Remember to append "/share/my-file" to the resulting store path when using it elsewhere:

```nix
writeShellScript "evaluate-my-file.sh" ''
  cat ${my-file}/share/my-file
''
```

**End note.**


### `writeText`

<a id="trivial-builder-writeText"></a>

Write a text file to the Nix store

`writeText` takes the following arguments:
a string.

`name` (String)

Definition: The name used in the Nix store path.

`text` (String)

Definition: The contents of the file.

The store path will include the name, and it will be a file.

<a id="ex-writeText"></a>

**Example**

# Usage of `writeText`

Write the string `Contents of File` to `/nix/store/<store path>`:

```nix
writeText "my-file" ''
  Contents of File
''
```

**End example.**


This is equivalent to:

```nix
writeTextFile {
  name = "my-file";
  text = ''
    Contents of File
  '';
}
```


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/trivial-build-helpers.chapter.md)


## `writeShellApplication`

<a id="trivial-builder-writeShellApplication"></a>

`writeShellApplication` is similar to `writeShellScriptBin` and `writeScriptBin` but supports runtime dependencies with `runtimeInputs`.
Writes an executable shell script to `/nix/store/<store path>/bin/<name>` and checks its syntax with [`shellcheck`](https://github.com/koalaman/shellcheck) and the `bash`'s `-n` option.
Some basic Bash options are set by default (`errexit`, `nounset`, and `pipefail`), but can be overridden with `bashOptions`.

Extra arguments may be passed to `stdenv.mkDerivation` by setting `derivationArgs`; note that variables set in this manner will be set when the shell script is _built,_ not when it's run.
Runtime environment variables can be set with the `runtimeEnv` argument.

`writeShellApplication` has the following arguments:

`name` (String)

Definition: The name of the script to write.

`text` (String)

Definition: The shell script's text, not including a shebang.

`runtimeInputs` (List of derivations or strings, _optional_)

Definition: Inputs to add to the shell script's `$PATH` at runtime.

  Each elements can either be a normal derivation, or a string containing a path, in which case it will be suffixed with `/bin` to create a `PATH` expression (see [`lib.strings.makeBinPath`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/lib/strings.nix) (source section: lib.strings.makeBinPath) for more information).

`runtimeEnv` (Attribute set, _optional_)

Definition: Extra environment variables to set at runtime.

`checkPhase` (String, _optional_)

Definition: The `checkPhase` to run.

  The script path will be given as `$target` in the `checkPhase`

  _Default behavior:_ run [`shellcheck`](https://github.com/koalaman/shellcheck) (on supported platforms) and `bash -n` (check syntax but don't execute commands).

`excludeShellChecks` (List of strings, _optional_)

Definition: Checks to exclude when running `shellcheck`.

  For example, `excludeShellChecks = [ "SC2016" ]` would prevent `shellcheck` from reporting `SC2016`, but would still detect any other problems.

  See [the `shellcheck` wiki](https://www.shellcheck.net/wiki/) for a list of checks.

`extraShellCheckFlags` (List of strings, _optional_)

Definition: Extra command-line flags to pass to `shellcheck`.

`bashOptions` (List of strings, _optional_)

Definition: Bash options to activate with `set -o` at the start of the script

  _Default:_ `[ "errexit" "nounset" "pipefail" ]`, which means:
  1. A failing command inside of a command list or pipeline will make the script exit, except if used as a conditional (inside a `while`, `if`, `&&`, `||`, etc.);
  2. Any attempt to expand an undefined variable will make the script exit.

`inheritPath` (Bool, _optional_)

Definition: Whether the script will inherit the PATH from its parent environment.

  _Default:_ `true`

`meta` (Attribute set, _optional_)

Definition: `stdenv.mkDerivation`'s [`meta`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/meta.chapter.md) (source section: Meta-attributes) argument

`passthru` (Attribute set, _optional_)

Definition: `stdenv.mkDerivation`'s [`passthru`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/passthru.chapter.md) (source section: Passthru-attributes) argument

`derivationArgs` (Attribute set, _optional_)

Definition: Extra arguments to pass to [`stdenv.mkDerivation`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: The Standard Environment)

**Caution**

  Certain derivation attributes are also set internally, so overriding those could cause problems.

**End caution.**


<a id="ex-writeShellApplication"></a>

**Example**

# Usage of `writeShellApplication`

The following shell application can refer to `curl` directly, rather than needing to write `${curl}/bin/curl`

```nix
writeShellApplication {
  name = "show-nixos-org";

  runtimeInputs = [
    curl
    w3m
  ];

  text = ''
    curl -s 'https://nixos.org' | w3m -dump -T text/html
  '';
}
```

**End example.**



[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/build-helpers/special/mkshell.section.md)


# pkgs.mkShell

<a id="sec-pkgs-mkShell"></a>

`pkgs.mkShell` is a specialized `stdenv.mkDerivation` that removes some
repetition when using it with `nix-shell` (or `nix develop`).

## Usage

<a id="sec-pkgs-mkShell-usage"></a>

Here is a common usage example:

```nix
{
  pkgs ? import <nixpkgs> { },
}:
pkgs.mkShell {
  packages = [ pkgs.gnumake ];

  inputsFrom = [
    pkgs.hello
    pkgs.gnutar
  ];

  shellHook = ''
    export DEBUG=1
  '';
}
```

## Attributes

<a id="sec-pkgs-mkShell-attributes"></a>

* `name` (default: `nix-shell`). Set the name of the derivation.
* `packages` (default: `[]`). Add executable packages to the `nix-shell` environment.
* `inputsFrom` (default: `[]`). Add build dependencies of the listed derivations to the `nix-shell` environment.
* `shellHook` (default: `""`). Bash statements that are executed by `nix-shell`.

... all the attributes of `stdenv.mkDerivation`.

## Variants

<a id="sec-pkgs-mkShell-variants"></a>

`pkgs.mkShellNoCC` is a variant that uses `stdenvNoCC` instead of `stdenv` as base environment. This is useful if no C compiler is needed in the shell environment.

## Building the shell

<a id="sec-pkgs-mkShell-building"></a>

This derivation output will contain a text file that contains a reference to
all the build inputs. This is useful in CI where we want to make sure that
every derivation, and its dependencies, build properly. Or when creating a GC
root so that the build dependencies don't get garbage-collected.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/python.section.md)

**Adaptation note:** The pinned upstream example repeats setuptools in its function arguments. Remove that duplicate when adapting the example; its source text is preserved below.


#### `buildPythonPackage` function

<a id="buildpythonpackage-function"></a>

The `buildPythonPackage` function has its name binding in
`pkgs/development/interpreters/python/python-packages-base.nix` and is
implemented in `pkgs/development/interpreters/python/mk-python-derivation.nix`
using setup hooks.

The following is an example:

```nix
{
  lib,
  buildPythonPackage,
  fetchPypi,

  # build-system
  setuptools,
  setuptools-scm,

  # dependencies
  attrs,
  pluggy,
  py,
  setuptools,
  six,

  # tests
  hypothesis,
}:

buildPythonPackage (finalAttrs: {
  pname = "pytest";
  version = "3.3.1";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;

    hash = "sha256-z4Q23FnYaVNG/NOrKW3kZCXsqwDWQJbOvnn7Ueyy65M=";
  };

  postPatch = ''
    # don't test bash builtins
    rm testing/test_argcomplete.py
  '';

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [
    attrs
    py
    setuptools
    six
    pluggy
  ];

  nativeCheckInputs = [ hypothesis ];

  meta = {
    changelog = "https://github.com/pytest-dev/pytest/releases/tag/${finalAttrs.version}";
    description = "Framework for writing tests";
    homepage = "https://github.com/pytest-dev/pytest";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      lovek323
      madjar
      lsix
    ];
  };
})
```

The `buildPythonPackage` mainly does four things:

* In the [`buildPhase`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: The build phase), it calls `${python.pythonOnBuildForHost.interpreter} -m build --wheel` to
  build a wheel binary zipfile.
* In the [`installPhase`](packaging.md#ssec-install-phase), it installs the wheel file using `${python.pythonOnBuildForHost.interpreter} -m installer *.whl`.
* In the [`postFixup`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: `postFixup`) phase, the `wrapPythonPrograms` bash function is called to
  wrap all programs in the `$out/bin/*` directory to include `$PATH`
  environment variable and add dependent libraries to script's `sys.path`.
* In the [`installCheck`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: The installCheck phase) phase, `${python.interpreter} -m pytest` is run.

By default tests are run because [`doCheck = true`](packaging.md#var-stdenv-doCheck). Test dependencies, like
e.g. the test runner, should be added to [`nativeCheckInputs`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/stdenv/stdenv.chapter.md) (source section: `nativeCheckInputs`).

By default `meta.platforms` is set to the same value
as the interpreter unless overridden otherwise.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/python.section.md)


#### `buildPythonApplication` function

<a id="buildpythonapplication-function"></a>

The [`buildPythonApplication`](helpers.md#buildpythonapplication-function) function is practically the same as
[`buildPythonPackage`](helpers.md#buildpythonpackage-function). The main purpose of this function is to build a Python
package where one is interested only in the executables, and not importable
modules. For that reason, when adding this package to a [`python.buildEnv`](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/python.section.md) (source section: `python.buildEnv` function), the
modules won't be made available.

Another difference is that [`buildPythonPackage`](helpers.md#buildpythonpackage-function) by default prefixes the names of
the packages with the version of the interpreter. Because this is irrelevant for
applications, the prefix is omitted.

When packaging a Python application with [`buildPythonApplication`](helpers.md#buildpythonapplication-function), it should be
called with `callPackage` and passed `python3` or `python3Packages` (or possibly
specifying an interpreter version such as `python313Packages`), like this:

```nix
{
  lib,
  python3Packages,
  fetchPypi,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "luigi";
  version = "2.7.9";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-Pe229rT0aHwA98s+nTHQMEFKZPo/yw6sot8MivFDvAw=";
  };

  build-system = with python3Packages; [ setuptools ];

  dependencies = with python3Packages; [
    tornado
    python-daemon
  ];

  meta = {
    # ...
  };
})
```

This is then added to `pkgs/by-name` just as any other application would be.

Since the package is an application, a consumer doesn't need to care about
Python versions or modules, which is why they don't go in `python3Packages`.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/javascript.section.md)


### buildNpmPackage

<a id="javascript-buildNpmPackage"></a>

`buildNpmPackage` packages npm-based projects in Nixpkgs without the use of an auto-generated dependencies file.
It uses npm's cache. It builds a reproducible cache of the project's dependencies and points npm at it.

Here's an example:

```nix
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage (finalAttrs: {
  pname = "flood";
  version = "4.7.0";

  src = fetchFromGitHub {
    owner = "jesec";
    repo = "flood";
    tag = "v${finalAttrs.version}";
    hash = "sha256-BR+ZGkBBfd0dSQqAvujsbgsEPFYw/ThrylxUbOksYxM=";
  };

  npmDepsHash = "sha256-tuEfyePwlOy2/mOPdXbqJskO6IowvAP4DWg8xSZwbJw=";

  # The prepack script runs the build script, which we'd rather do in the build phase.
  npmPackFlags = [ "--ignore-scripts" ];

  NODE_OPTIONS = "--openssl-legacy-provider";

  meta = {
    description = "Modern web UI for various torrent clients with a Node.js backend and React frontend";
    homepage = "https://flood.js.org";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ winter ];
  };
})
```

In the default `installPhase` set by `buildNpmPackage`, it uses `npm pack --json --dry-run` to decide what files to install. They go in `$out/lib/node_modules/$name/`, where `$name` is the `name` string in the package's `package.json`.
Additionally, the `bin` and `man` keys in the source's `package.json` are used to decide what binaries and manpages are supposed to be installed.
If these are not defined, `npm pack` may miss some files, and no binaries are produced.


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/go.section.md)


## Building Go modules with `buildGoModule`

<a id="ssec-language-go"></a>

The function `buildGoModule` builds Go programs managed with Go modules. It builds [Go Modules](https://go.dev/wiki/Modules) through a two phase build:

- An intermediate fetcher derivation called `goModules`. This derivation will be used to fetch all the dependencies of the Go module.
- A final derivation will use the output of the intermediate derivation to build the binaries and produce the final output.

### Example for `buildGoModule`

<a id="ex-buildGoModule"></a>

The following is an example expression using `buildGoModule`:

```nix
{
  pet = buildGoModule (finalAttrs: {
    pname = "pet";
    version = "0.3.4";

    src = fetchFromGitHub {
      owner = "knqyf263";
      repo = "pet";
      tag = "v${finalAttrs.version}";
      hash = "sha256-Gjw1dRrgM8D3G7v6WIM2+50r4HmTXvx0Xxme2fH9TlQ=";
    };

    vendorHash = "sha256-ciBIR+a1oaYH+H1PcC8cD8ncfJczk1IiJ8iYNM+R6aA=";

    meta = {
      description = "Simple command-line snippet manager, written in Go";
      homepage = "https://github.com/knqyf263/pet";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ kalbasit ];
    };
  });
}
```


[Upstream source](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/rust.section.md)


## `buildRustPackage`: Compiling Rust applications with Cargo

<a id="compiling-rust-applications-with-cargo"></a>

Rust applications are packaged by using the `buildRustPackage` helper from `rustPlatform`:

```nix
{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ripgrep";
  version = "14.1.1";

  src = fetchFromGitHub {
    owner = "BurntSushi";
    repo = "ripgrep";
    tag = finalAttrs.version;
    hash = "sha256-gyWnahj1A+iXUQlQ1O1H1u7K5euYQOld9qWm99Vjaeg=";
  };

  cargoHash = "sha256-9atn5qyBDy4P6iUoHFhg+TV6Ur71fiah4oTJbBMeEy4=";

  meta = {
    description = "Fast line-oriented regex search tool, similar to ag and ack";
    homepage = "https://github.com/BurntSushi/ripgrep";
    license = lib.licenses.unlicense;
    maintainers = [ ];
  };
})
```

`buildRustPackage` requires a `cargoHash` attribute, computed over all crate sources of this package.

**Warning**

`cargoSha256` is already deprecated, and is subject to removal in favor of
`cargoHash` which supports [SRI](https://www.w3.org/TR/SRI/) hashes.

If you are still using `cargoSha256`, you can simply replace it with
`cargoHash` and recompute the hash, or convert the original sha256 to SRI
hash using `nix-hash --to-sri --type sha256 "<original sha256>"`.

**End warning.**


```nix
{ cargoHash = "sha256-l1vL2ZdtDRxSGvP0X/l3nMw8+6WF67KPutJEzUROjg8="; }
```

If this method does not work, you can resort to copying the `Cargo.lock` file into Nixpkgs
and importing it as described in the [next section](https://github.com/NixOS/nixpkgs/blob/4593931c855e7cf2ab412b659dd2841030f753df/doc/languages-frameworks/rust.section.md) (source section: Importing a `Cargo.lock` file).

Both types of hashes are permitted when contributing to Nixpkgs. The
Cargo hash is obtained by inserting a fake checksum into the
expression and building the package once. The correct checksum can
then be taken from the failed build. A fake hash can be used for
`cargoHash` as follows:

```nix
{ cargoHash = lib.fakeHash; }
```

Per the instructions in the [Cargo Book](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html)
best practices guide, Rust applications should always commit the `Cargo.lock`
file in git to ensure a reproducible build. However, a few packages do not, and
Nix depends on this file, so if it is missing you can use `cargoPatches` to
apply it in the `patchPhase`. Consider sending a PR upstream with a note to the
maintainer describing why it's important to include in the application.

The fetcher will verify that the `Cargo.lock` file is in sync with the `src`
attribute, and fail the build if not. It will also will compress the vendor
directory into a tar.gz archive.

The tarball with vendored dependencies contains a directory with the
package's `name`, which is normally composed of `pname` and
`version`. This means that the vendored dependencies hash
(`cargoHash`) is dependent on the package name and
version. The `cargoDepsName` attribute can be used to use another name
for the directory of vendored dependencies. For example, the hash can
be made invariant to the version by setting `cargoDepsName` to
`pname`:

```nix
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "broot";
  version = "1.2.0";

  src = fetchCrate {
    inherit (finalAttrs) pname version;
    hash = "sha256-aDQA4A5mScX9or3Lyiv/5GyAehidnpKKE0grhbP1Ctc=";
  };

  cargoHash = "sha256-iDYh52rj1M5Uupvbx2WeDd/jvQZ+2A50V5rp5e2t7q4=";
  cargoDepsName = finalAttrs.pname;

  # ...
})
```
