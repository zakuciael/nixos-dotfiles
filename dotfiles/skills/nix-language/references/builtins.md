# Built-in reference

Nix 2.35.2; upstream revision `2c73b59da29606068c0c98db015dd3a66955525d`.

Selected upstream excerpts, with links adapted for this package. Copyright the Nix contributors; see [COPYING](../COPYING).

- [attrNames](#builtins-attrNames)
- [currentSystem](#builtins-currentSystem)
- [deepSeq](#builtins-deepSeq)
- [filter](#builtins-filter)
- [foldl'](#builtins-foldl')
- [getContext](#builtins-getContext)
- [getEnv](#builtins-getEnv)
- [hasAttr](#builtins-hasAttr)
- [import](#builtins-import)
- [isAttrs](#builtins-isAttrs)
- [listToAttrs](#builtins-listToAttrs)
- [map](#builtins-map)
- [mapAttrs](#builtins-mapAttrs)
- [outputOf](#builtins-outputOf)
- [readFile](#builtins-readFile)
- [seq](#builtins-seq)
- [toString](#builtins-toString)
- [trace](#builtins-trace)
- [tryEval](#builtins-tryEval)
- [typeOf](#builtins-typeOf)

[Upstream generator](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/generate-builtins.nix)

<dl>
<dt id="builtins-attrNames">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-attrNames"><code>attrNames <var>set</var></code></a>
</dt>
<dd>

Return the names of the attributes in the set *set* in an
alphabetically sorted list. For instance, `builtins.attrNames { y
= 1; x = "foo"; }` evaluates to `[ "x" "y" ]`.

Has `O(n log n)` time complexity, where `n` is number of attributes in the *set*.

</dd>

<dt id="builtins-currentSystem">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-currentSystem"><code>currentSystem</code></a> (string)
</dt>
<dd>

The value of the
[`eval-system`](https://nix.dev/manual/nix/2.35/command-ref/conf-file.html#conf-eval-system)
or else
[`system`](https://nix.dev/manual/nix/2.35/command-ref/conf-file.html#conf-system)
configuration option.

It can be used to set the `system` attribute for [`builtins.derivation`](https://nix.dev/manual/nix/2.35/language/derivations.html) such that the resulting derivation can be built on the same system that evaluates the Nix expression:

```nix
 builtins.derivation {
   # ...
   system = builtins.currentSystem;
}
```

It can be overridden in order to create derivations for different system than the current one:

```console
$ nix-instantiate --system "mips64-linux" --eval --expr 'builtins.currentSystem'
"mips64-linux"
```

> **Note**
>
> Not available in [pure evaluation mode](https://nix.dev/manual/nix/2.35/command-ref/conf-file.html#conf-pure-eval).

</dd>

<dt id="builtins-deepSeq">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-deepSeq"><code>deepSeq <var>e1</var> <var>e2</var></code></a>
</dt>
<dd>

This is like `seq e1 e2`, except that *e1* is evaluated *deeply*:
if it’s a list or set, its elements or attributes are also
evaluated recursively.

</dd>

<dt id="builtins-filter">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-filter"><code>filter <var>f</var> <var>list</var></code></a>
</dt>
<dd>

Return a list consisting of the elements of *list* for which the
function *f* returns `true`.
Has linear time complexity in the size of the input *list*.

</dd>

<dt id="builtins-foldl'">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-foldl'"><code>foldl' <var>op</var> <var>nul</var> <var>list</var></code></a>
</dt>
<dd>

Reduce a list by applying a binary operator, from left to right,
e.g.
```nix
foldl' op nul [ x0 x1 x2 ]
  =
    let
      strictly = f: a: builtins.seq a (f a);
      y0 = op nul x0;
      y1 = strictly op y0 x1;
      y2 = strictly op y1 x2;
    in
      y2

  # and, ignoring strictness/laziness
  ==
    op (op (op nul x0) x1) x2
```

For example, `foldl' (acc: elem: acc + elem) 0 [1 2 3]` evaluates
to `6` and `foldl' (acc: elem: { "${elem}" = elem; } // acc) {}
["a" "b"]` evaluates to `{ a = "a"; b = "b"; }`.

The first argument of `op` is the accumulator whereas the second
argument is the current element being processed.

The return value of each application of `op` is evaluated immediately,
even for intermediate values.
This way, `foldl'` can operate in constant stack space, allowing it to operate on large lists,
regardless of [max-call-depth](https://nix.dev/manual/nix/2.35/command-ref/conf-file.html#conf-max-call-depth).

Conventionally, a fold function without the `'` ("prime") preserves laziness,
but lacks these benefits.
See also [Nixpkgs `lib.foldl`](https://nixos.org/manual/nixpkgs/unstable/#function-library-lib.lists.foldl).

Has linear time complexity in the size of the list.

</dd>

<dt id="builtins-getContext">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-getContext"><code>getContext <var>s</var></code></a>
</dt>
<dd>

Return the string context of *s*.

The string context tracks references to derivations within a string.
It is represented as an attribute set of [store derivation](https://nix.dev/manual/nix/2.35/glossary.html#gloss-store-derivation) paths mapping to output names.

Using [string interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html) on a derivation adds that derivation to the string context.
For example,

```nix
builtins.getContext "${derivation { name = "a"; builder = "b"; system = "c"; }}"
```

evaluates to

```
{ "/nix/store/arhvjaf6zmlyn8vh8fgn55rpwnxq0n7l-a.drv" = { outputs = [ "out" ]; }; }
```

</dd>

<dt id="builtins-getEnv">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-getEnv"><code>getEnv <var>s</var></code></a>
</dt>
<dd>

`getEnv` returns the value of the environment variable *s*, or an
empty string if the variable doesn’t exist. This function should be
used with care, as it can introduce all sorts of nasty environment
dependencies in your Nix expression.

`getEnv` is used in Nix Packages to locate the file
`~/.nixpkgs/config.nix`, which contains user-local settings for Nix
Packages. (That is, it does a `getEnv "HOME"` to locate the user’s
home directory.)

</dd>

<dt id="builtins-hasAttr">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-hasAttr"><code>hasAttr <var>s</var> <var>set</var></code></a>
</dt>
<dd>

`hasAttr` returns `true` if *set* has an attribute named *s*, and
`false` otherwise. This is a dynamic version of the `?` operator,
since *s* is an expression rather than an identifier.

Has `O(log n)` time complexity, where `n` is number of attributes in the *set*.

</dd>

<dt id="builtins-import">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-import"><code>import <var>path</var></code></a>
</dt>
<dd>

Load, parse, and return the Nix expression in the file *path*.

> **Note**
>
> Unlike some languages, `import` is a regular function in Nix.

The *path* argument must meet the same criteria as an [interpolated expression](https://nix.dev/manual/nix/2.35/language/string-interpolation.html#interpolated-expression).

If *path* is a directory, the file `default.nix` in that directory is used if it exists.

> **Example**
>
> ```console
> $ echo 123 > default.nix
> ```
>
> Import `default.nix` from the current directory.
>
> ```nix
> import ./.
> ```
>
>     123

Evaluation aborts if the file doesn’t exist or contains an invalid Nix expression.

A Nix expression loaded by `import` must not contain any *free variables*, that is, identifiers that are not defined in the Nix expression itself and are not built-in.
Therefore, it cannot refer to variables that are in scope at the call site.

> **Example**
>
> If you have a calling expression
>
> ```nix
> rec {
>   x = 123;
>   y = import ./foo.nix;
> }
> ```
>
>  then the following `foo.nix` throws an error:
>
>  ```nix
>  # foo.nix
>  x + 456
>  ```
>
>  since `x` is not in scope in `foo.nix`.
> If you want `x` to be available in `foo.nix`, pass it as a function argument:
>
>  ```nix
>  rec {
>    x = 123;
>    y = import ./foo.nix x;
>  }
>  ```
>
>  and
>
>  ```nix
>  # foo.nix
>  x: x + 456
>  ```
>
>  The function argument doesn’t have to be called `x` in `foo.nix`; any name would work.

</dd>

<dt id="builtins-isAttrs">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-isAttrs"><code>isAttrs <var>e</var></code></a>
</dt>
<dd>

Return `true` if *e* evaluates to a set, and `false` otherwise.

</dd>

<dt id="builtins-listToAttrs">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-listToAttrs"><code>listToAttrs <var>e</var></code></a>
</dt>
<dd>

Construct a set from a list specifying the names and values of each
attribute. Each element of the list should be a set consisting of a
string-valued attribute `name` specifying the name of the attribute,
and an attribute `value` specifying its value.

In case of duplicate occurrences of the same name, the first
takes precedence.

Example:

```nix
builtins.listToAttrs
  [ { name = "foo"; value = 123; }
    { name = "bar"; value = 456; }
    { name = "bar"; value = 420; }
  ]
```

evaluates to

```nix
{ foo = 123; bar = 456; }
```

Has `O(n log n)` time complexity, where `n` is size of the list.

</dd>

<dt id="builtins-map">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-map"><code>map <var>f</var> <var>list</var></code></a>
</dt>
<dd>

Apply the function *f* to each element in the list *list*. For
example,

```nix
map (x: "foo" + x) [ "bar" "bla" "abc" ]
```

evaluates to `[ "foobar" "foobla" "fooabc" ]`.

Has `O(n)` time complexity, where `n` is the size of the *list*.
Note that no calls to *f* are performed by the builtin, but *f* itself is evaluated and its type is checked eagerly.
The function *f* is called on demand when a resulting list element is evaluated.

</dd>

<dt id="builtins-mapAttrs">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-mapAttrs"><code>mapAttrs <var>f</var> <var>attrset</var></code></a>
</dt>
<dd>

Apply function *f* to every element of *attrset*. For example,

```nix
builtins.mapAttrs (name: value: value * 10) { a = 1; b = 2; }
```

evaluates to `{ a = 10; b = 20; }`.

Has `O(n)` time complexity, where `n` is the size of the *attrset*.
Note that no calls to *f* are performed by the builtin.
The function *f* is called on demand when a resulting attribute value is evaluated.

</dd>

<dt id="builtins-outputOf">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-outputOf"><code>outputOf <var>derivation-reference</var> <var>output-name</var></code></a>
</dt>
<dd>

> **Note**
>
> This function is only available if the [`dynamic-derivations` experimental feature](https://nix.dev/manual/nix/2.35/development/experimental-features.html#xp-feature-dynamic-derivations) is enabled.
>
> For example, include the following in [`nix.conf`](https://nix.dev/manual/nix/2.35/command-ref/conf-file.html):
>
> ```
> extra-experimental-features = dynamic-derivations
> ```

Return the output path of a derivation, literally or using an
[input placeholder string](https://nix.dev/manual/nix/2.35/store/derivation/index.html#input-placeholder)
if needed.

If the derivation has a statically-known output path (i.e. the derivation output is input-addressed, or fixed content-addressed), the output path is returned.
But if the derivation is content-addressed or if the derivation is itself not-statically produced (i.e. is the output of another derivation), an input placeholder is returned instead.

*`derivation reference`* must be a string that may contain a regular store path to a derivation, or may be an input placeholder reference.
If the derivation is produced by a derivation, you must explicitly select `drv.outPath`.
This primop can be chained arbitrarily deeply.
For instance,

```nix
builtins.outputOf
  (builtins.outputOf myDrv "out")
  "out"
```

returns an input placeholder for the output of the output of `myDrv`.

This primop corresponds to the `^` sigil for [deriving paths](https://nix.dev/manual/nix/2.35/glossary.html#gloss-deriving-path), e.g. as part of installable syntax on the command line.

</dd>

<dt id="builtins-readFile">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-readFile"><code>readFile <var>path</var></code></a>
</dt>
<dd>

Return the contents of the file *path* as a string.

</dd>

<dt id="builtins-seq">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-seq"><code>seq <var>e1</var> <var>e2</var></code></a>
</dt>
<dd>

Evaluate *e1*, then evaluate and return *e2*. This ensures that a
computation is strict in the value of *e1*.

</dd>

<dt id="builtins-toString">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-toString"><code>toString <var>e</var></code></a>
</dt>
<dd>

Convert the expression *e* to a string. *e* can be:

  - A string (in which case the string is returned unmodified).

  - A path (e.g., `toString /foo/bar` yields `"/foo/bar"`.

  - A set containing `{ __toString = self: ...; }` or `{ outPath = ...; }`.

  - An integer.

  - A list, in which case the string representations of its elements
    are joined with spaces.

  - A Boolean (`false` yields `""`, `true` yields `"1"`).

  - `null`, which yields the empty string.

</dd>

<dt id="builtins-trace">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-trace"><code>trace <var>e1</var> <var>e2</var></code></a>
</dt>
<dd>

Evaluate *e1* and print its abstract syntax representation on
standard error. Then return *e2*. This function is useful for
debugging.

If the
[`debugger-on-trace`](https://nix.dev/manual/nix/2.35/command-ref/conf-file.html#conf-debugger-on-trace)
option is set to `true` and the `--debugger` flag is given, the
interactive debugger is started when `trace` is called (like
[`break`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-break)).

</dd>

<dt id="builtins-tryEval">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-tryEval"><code>tryEval <var>e</var></code></a>
</dt>
<dd>

Try to shallowly evaluate *e*. Return a set containing the
attributes `success` (`true` if *e* evaluated successfully,
`false` if an error was thrown) and `value`, equalling *e* if
successful and `false` otherwise. `tryEval` only prevents
errors created by `throw` or `assert` from being thrown.
Errors `tryEval` doesn't catch are, for example, those created
by `abort` and type errors generated by builtins. Also note that
this doesn't evaluate *e* deeply, so `let e = { x = throw ""; };
in (builtins.tryEval e).success` is `true`. Using
`builtins.deepSeq` one can get the expected result:
`let e = { x = throw ""; }; in
(builtins.tryEval (builtins.deepSeq e e)).success` is
`false`.

`tryEval` intentionally does not return the error message, because that risks bringing non-determinism into the evaluation result, and it would become very difficult to improve error reporting without breaking existing expressions.
Instead, use [`builtins.addErrorContext`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-addErrorContext) to add context to the error message, and use a Nix unit testing tool for testing.

</dd>

<dt id="builtins-typeOf">
  <a href="https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-typeOf"><code>typeOf <var>e</var></code></a>
</dt>
<dd>

Return a string representing the type of the value *e*, namely
`"int"`, `"bool"`, `"string"`, `"path"`, `"null"`, `"set"`,
`"list"`, `"lambda"` or `"float"`.

</dd>
</dl>
