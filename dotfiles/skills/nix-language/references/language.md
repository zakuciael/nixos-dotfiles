# Language reference

Nix 2.35.2; upstream revision `2c73b59da29606068c0c98db015dd3a66955525d`.

Selected upstream excerpts, with links adapted for this package. Copyright the Nix contributors; see [COPYING](../COPYING).

- [Data Types](#section-1)
- [Path](#section-2)
- [List](#section-3)
- [Attribute Set](#section-4)
- [Recursive sets](#section-5)
- [Let-expressions](#section-6)
- [Functions](#section-7)
- [With-expressions](#section-8)
- [Operators](#section-9)
- [Update](#section-10)
- [Scoping rules](#section-11)
- [Laziness and thunks](#section-12)
- [Strictness](#section-13)
- [String literals](#section-14)
- [Interpolated expression](#section-15)
- [String context](#section-16)
- [Inspecting string contexts](#section-17)
- [Clearing string contexts](#section-18)
- [Derivations](#section-19)
- [Required](#section-20)

<a id="section-1"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/types.md)

# Data Types

Every value in the Nix language has one of the following types:

* [Integer](https://nix.dev/manual/nix/2.35/language/types.html#type-int)
* [Float](https://nix.dev/manual/nix/2.35/language/types.html#type-float)
* [Boolean](https://nix.dev/manual/nix/2.35/language/types.html#type-bool)
* [String](https://nix.dev/manual/nix/2.35/language/types.html#type-string)
* [Path](https://nix.dev/manual/nix/2.35/language/types.html#type-path)
* [Null](https://nix.dev/manual/nix/2.35/language/types.html#type-null)
* [Attribute set](https://nix.dev/manual/nix/2.35/language/types.html#type-attrs)
* [List](https://nix.dev/manual/nix/2.35/language/types.html#type-list)
* [Function](https://nix.dev/manual/nix/2.35/language/types.html#type-function)
* [External](https://nix.dev/manual/nix/2.35/language/types.html#type-external)

<a id="section-2"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/types.md)

### Path <a id="type-path"></a>

A _path_ in the Nix language is an immutable, finite-length sequence of bytes starting with `/`, representing a POSIX-style, canonical file system path.
Path values are distinct from string values, even if they contain the same sequence of bytes.
Operations that produce paths will simplify the result as the standard C function [`realpath`](https://pubs.opengroup.org/onlinepubs/9699919799/functions/realpath.html) would, except that there is no symbolic link resolution.


Paths are suitable for referring to local files, and are often preferable over strings.
- Path values do not contain trailing or duplicate slashes, `.`, or `..`.
- Relative path literals are automatically resolved relative to their [base directory](https://nix.dev/manual/nix/2.35/glossary.html#gloss-base-directory).
- Tooling can recognize path literals and provide additional features, such as autocompletion, refactoring automation and jump-to-file.


A file is not required to exist at a given path in order for that path value to be valid, but a path that is converted to a string with [string interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html#interpolated-expression) or [string-and-path concatenation](https://nix.dev/manual/nix/2.35/language/operators.html#string-and-path-concatenation) must resolve to a readable file or directory which will be copied into the Nix store.
For instance, evaluating `"${./foo.txt}"` will cause `foo.txt` from the same directory to be copied into the Nix store and result in the string `"/nix/store/<hash>-foo.txt"`.
Operations such as [`import`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-import) can also expect a path to resolve to a readable file or directory.


> **Note**
>
> The Nix language assumes that all input files will remain _unchanged_ while evaluating a Nix expression.
> For example, assume you used a file path in an interpolated string during a `nix repl` session.
> Later in the same session, after having changed the file contents, evaluating the interpolated string with the file path again might not return a new [store path](https://nix.dev/manual/nix/2.35/store/store-path.html), since Nix might not re-read the file contents.
> Use `:r` to reset the repl as needed.


Path values can be expressed as [path literals](https://nix.dev/manual/nix/2.35/language/syntax.html#path-literal).
The function [`builtins.isPath`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-isPath) can be used to determine if a value is a path.

<a id="section-3"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/syntax.md)

## List <a id="list-literal"></a>

Lists are formed by enclosing a whitespace-separated list of values
between square brackets. For example,

```nix
[ 123 ./foo.nix "abc" (f { x = y; }) ]
```

defines a list of four elements, the last being the result of a call to
the function `f`. Note that function calls have to be enclosed in
parentheses. If they had been omitted, e.g.,

```nix
[ 123 ./foo.nix "abc" f { x = y; } ]
```

the result would be a list of five elements, the fourth one being a
function and the fifth being a set.

Note that lists are only lazy in values, and they are strict in length.

Elements in a list can be accessed using [`builtins.elemAt`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-elemAt).

<a id="section-4"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/syntax.md)

## Attribute Set <a id="attrs-literal"></a>

An attribute set is a collection of name-value-pairs called *attributes*.

Attribute sets are written enclosed in curly brackets (`{ }`).
Attribute names and attribute values are separated by an equal sign (`=`).
Each value can be an arbitrary expression, terminated by a semicolon (`;`)

An attribute name is a string without context, and is denoted by a [name](https://nix.dev/manual/nix/2.35/language/identifiers.html#names) (an [identifier](https://nix.dev/manual/nix/2.35/language/identifiers.html#identifiers) or [string literal](https://nix.dev/manual/nix/2.35/language/string-literals.html)).


> **Syntax**
>
> *attrset* → `{` { *name* `=` *expr* `;` } `}`

Attributes can appear in any order.
An attribute name may only occur once in each attribute set.

> **Example**
>
> This defines an attribute set with attributes named:
> - `x` with the value `123`, an integer
> - `text` with the value `"Hello"`, a string
> - `y` where the value is the result of applying the function `f` to the attribute set `{ bla = 456; }`
>
> ```nix
> {
>   x = 123;
>   text = "Hello";
>   y = f { bla = 456; };
> }
> ```

Attributes in nested attribute sets can be written using *attribute paths*.

> **Syntax**
>
> *attrset* → `{` { *attrpath* `=` *expr* `;` } `}`

An attribute path is a dot-separated list of [names](https://nix.dev/manual/nix/2.35/language/identifiers.html#names).

> **Syntax**
>
> *attrpath* = *name* { `.` *name* }

<!-- -->

> **Example**
>
> ```nix
> { a.b.c = 1; a.b.d = 2; }
> ```
>
>     {
>       a = {
>         b = {
>           c = 1;
>           d = 2;
>         };
>       };
>     }

Attribute names can also be set implicitly by using the [`inherit` keyword](https://nix.dev/manual/nix/2.35/language/syntax.html#inheriting-attributes).

> **Example**
>
> ```nix
> { inherit (builtins) true; }
> ```
>
>     { true = true; }

Attributes can be accessed with the [`.` operator](https://nix.dev/manual/nix/2.35/language/operators.html#attribute-selection).

Example:

```nix
{ a = "Foo"; b = "Bar"; }.a
```

This evaluates to `"Foo"`.

It is possible to provide a default value in an attribute selection using the `or` keyword.

Example:

```nix
{ a = "Foo"; b = "Bar"; }.c or "Xyzzy"
```

```nix
{ a = "Foo"; b = "Bar"; }.c.d.e.f.g or "Xyzzy"
```

will both evaluate to `"Xyzzy"` because there is no `c` attribute in the set.

You can use arbitrary double-quoted strings as attribute names:

```nix
{ "$!@#?" = 123; }."$!@#?"
```

```nix
let bar = "bar"; in
{ "foo ${bar}" = 123; }."foo ${bar}"
```

Both will evaluate to `123`.

Attribute names support [string interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html):

```nix
let bar = "foo"; in
{ foo = 123; }.${bar}
```

```nix
let bar = "foo"; in
{ ${bar} = 123; }.foo
```

Both will evaluate to `123`.

In the special case where an attribute name inside of a set declaration
evaluates to `null` (which is normally an error, as `null` cannot be coerced to
a string), that attribute is simply not added to the set:

```nix
{ ${if foo then "bar" else null} = true; }
```

This will evaluate to `{}` if `foo` evaluates to `false`.

A set that has a [`__functor`]<a id="attr-__functor"></a> attribute whose value is callable (i.e. is
itself a function or a set with a `__functor` attribute whose value is
callable) can be applied as if it were a function, with the set itself
passed in first , e.g.,

```nix
let add = { __functor = self: x: x + self.x; };
    inc = add // { x = 1; }; # inc is { x = 1; __functor = (...) }
in inc 1 # equivalent of `add.__functor add 1` i.e. `1 + self.x`
```

evaluates to `2`. This can be used to attach metadata to a function
without the caller needing to treat it specially, or to implement a form
of object-oriented programming, for example.

<a id="section-5"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/syntax.md)

## Recursive sets

Recursive sets are like normal [attribute sets](https://nix.dev/manual/nix/2.35/language/types.html#type-attrs), but the attributes can refer to each other.

> *rec-attrset* = `rec {` [ *name* `=` *expr* `;` `]`... `}`

Example:

```nix
rec {
  x = y;
  y = 123;
}.x
```

This evaluates to `123`.

Note that without `rec` the binding `x = y;` would
refer to the variable `y` in the surrounding scope, if one exists, and
would be invalid if no such variable exists. That is, in a normal
(non-recursive) set, attributes are not added to the lexical scope; in a
recursive set, they are.

Recursive sets of course introduce the danger of infinite recursion. For
example, the expression

```nix
rec {
  x = y;
  y = x;
}.x
```

will crash with an `infinite recursion encountered` error message.

<a id="section-6"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/syntax.md)

## Let-expressions

A let-expression allows you to define local variables for an expression.

> *let-in* = `let` [ *identifier* = *expr* `;` ]... `in` *expr*

Example:

```nix
let
  x = "foo";
  y = "bar";
in x + y
```

This evaluates to `"foobar"`.

There is also another, older, syntax for let expressions that should not be used in new code:

> *let* = `let` `{` *identifier* = *expr* `;` [ *identifier* = *expr* `;`]...  `}`

In this form, the attribute set between the `{` `}` is recursive.

One of the attributes must have the special name `body`,
which is the result of the expression.

Example:

```nix
let {
  foo = bar;
  bar = "baz";
  body = foo;
}
```

This evaluates to "baz".

<a id="section-7"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/syntax.md)

## Functions

Functions have the following form:

```nix
pattern: body
```

The pattern specifies what the argument of the function must look like,
and binds variables in the body to (parts of) the argument. There are
three kinds of patterns:

  - If a pattern is a single identifier, then the function matches any
    argument. Example:

    ```nix
    let negate = x: !x;
        concat = x: y: x + y;
    in if negate true then concat "foo" "bar" else ""
    ```

    Note that `concat` is a function that takes one argument and returns
    a function that takes another argument. This allows partial
    parameterisation (i.e., only filling some of the arguments of a
    function); e.g.,

    ```nix
    map (concat "foo") [ "bar" "bla" "abc" ]
    ```

    evaluates to `[ "foobar" "foobla" "fooabc" ]`.

  - A *set pattern* of the form `{ name1, name2, …, nameN }` matches a
    set containing the listed attributes, and binds the values of those
    attributes to variables in the function body. For example, the
    function

    ```nix
    { x, y, z }: z + y + x
    ```

    can only be called with a set containing exactly the attributes `x`,
    `y` and `z`. No other attributes are allowed. If you want to allow
    additional arguments, you can use an ellipsis (`...`):

    ```nix
    { x, y, z, ... }: z + y + x
    ```

    This works on any set that contains at least the three named
    attributes.

  - It is possible to provide *default values* for attributes, in
    which case they are allowed to be missing. A default value is
    specified by writing `name ?  e`, where *e* is an arbitrary
    expression. For example,

    ```nix
    { x, y ? "foo", z ? "bar" }: z + y + x
    ```

    specifies a function that only requires an attribute named `x`, but
    optionally accepts `y` and `z`.

  - An `@`-pattern provides a means of referring to the whole value
    being matched:

    ```nix
    args@{ x, y, z, ... }: z + y + x + args.a
    ```

    but can also be written as:

    ```nix
    { x, y, z, ... } @ args: z + y + x + args.a
    ```

    Here `args` is bound to the argument *as passed*, which is further
    matched against the pattern `{ x, y, z, ... }`.
    The `@`-pattern makes mainly sense with an ellipsis(`...`) as
    you can access attribute names as `a`, using `args.a`, which was
    given as an additional attribute to the function.

    > **Warning**
    >
    > `args@` binds the name `args` to the attribute set that is passed to the function.
    > In particular, `args` does *not* include any default values specified with `?` in the function's set pattern.
    >
    > For instance
    >
    > ```nix
    > let
    >   f = args@{ a ? 23, ... }: [ a args ];
    > in
    >   f {}
    > ```
    >
    > is equivalent to
    >
    > ```nix
    > let
    >   f = args @ { ... }: [ (args.a or 23) args ];
    > in
    >   f {}
    > ```
    >
    > and both expressions will evaluate to:
    >
    > ```nix
    > [ 23 {} ]
    > ```

  - All bindings introduced by the function are in scope in the entire function expression; not just in the body.
    It can therefore be used in default values.

    > **Example**
    >
    > A parameter (`x`), is used in the default value for another parameter (`y`):
    >
    > ```nix
    > let
    >   f = { x, y ? [x] }: { inherit y; };
    > in
    >   f { x = 3; }
    > ```
    >
    > This evaluates to:
    >
    > ```nix
    > {
    >   y = [ 3 ];
    > }
    > ```

    > **Example**
    >
    > The binding of an `@` pattern, `args`, is used in the default value for a parameter, `x`:
    >
    > ```nix
    > let
    >   f = args@{ x ? args.a, ... }: x;
    > in
    >   f { a = 1; }
    > ```
    >
    > This evaluates to:
    >
    > ```nix
    > 1
    > ```

Note that functions do not have names. If you want to give them a name,
you can bind them to an attribute, e.g.,

```nix
let concat = { x, y }: x + y;
in concat { x = "foo"; y = "bar"; }
```

<a id="section-8"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/syntax.md)

## With-expressions

A *with-expression*,

```nix
with e1; e2
```

introduces the set *e1* into the lexical scope of the expression *e2*.
For instance,

```nix
let as = { x = "foo"; y = "bar"; };
in with as; x + y
```

evaluates to `"foobar"` since the `with` adds the `x` and `y` attributes
of `as` to the lexical scope in the expression `x + y`. The most common
use of `with` is in conjunction with the `import` function. E.g.,

```nix
with (import ./definitions.nix); ...
```

makes all attributes defined in the file `definitions.nix` available as
if they were defined locally in a `let`-expression.

The bindings introduced by `with` do not shadow bindings introduced by
other means, e.g.

```nix
let a = 3; in with { a = 1; }; let a = 4; in with { a = 2; }; ...
```

establishes the same scope as

```nix
let a = 1; in let a = 2; in let a = 3; in let a = 4; in ...
```

Variables coming from outer `with` expressions *are* shadowed:

```nix
with { a = "outer"; };
with { a = "inner"; };
a
```

Does evaluate to `"inner"`.

<a id="section-9"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/operators.md)

# Operators

| Name                                   | Syntax                                     | Associativity | Precedence |
|----------------------------------------|--------------------------------------------|---------------|------------|
| [Attribute selection](https://nix.dev/manual/nix/2.35/language/operators.html#attribute-selection)                  | *attrset* `.` *attrpath* \[ `or` *expr* \] | none          | 1          |
| [Function application](https://nix.dev/manual/nix/2.35/language/operators.html#function-application)                 | *func* *expr*                              | left          | 2          |
| [Arithmetic negation](https://nix.dev/manual/nix/2.35/language/operators.html#arithmetic)      | `-` *number*                               | none          | 3          |
| [Has attribute](https://nix.dev/manual/nix/2.35/language/operators.html#has-attribute)                        | *attrset* `?` *attrpath*                   | none          | 4          |
| List concatenation                     | *list* `++` *list*                         | right         | 5          |
| [Multiplication](https://nix.dev/manual/nix/2.35/language/operators.html#arithmetic)           | *number* `*` *number*                      | left          | 6          |
| [Division](https://nix.dev/manual/nix/2.35/language/operators.html#arithmetic)                 | *number* `/` *number*                      | left          | 6          |
| [Subtraction](https://nix.dev/manual/nix/2.35/language/operators.html#arithmetic)              | *number* `-` *number*                      | left          | 7          |
| [Addition](https://nix.dev/manual/nix/2.35/language/operators.html#arithmetic)                 | *number* `+` *number*                      | left          | 7          |
| [String concatenation](https://nix.dev/manual/nix/2.35/language/operators.html#string-concatenation)                 | *string* `+` *string*                      | left          | 7          |
| [Path concatenation](https://nix.dev/manual/nix/2.35/language/operators.html#path-concatenation)                   | *path* `+` *path*                          | left          | 7          |
| [Path and string concatenation](https://nix.dev/manual/nix/2.35/language/operators.html#path-and-string-concatenation)        | *path* `+` *string*                        | left          | 7          |
| [String and path concatenation](https://nix.dev/manual/nix/2.35/language/operators.html#string-and-path-concatenation)        | *string* `+` *path*                        | left          | 7          |
| Logical negation (`NOT`)               | `!` *bool*                                 | none          | 8          |
| [Update](https://nix.dev/manual/nix/2.35/language/operators.html#update)                               | *attrset* `//` *attrset*                   | right         | 9          |
| [Less than](https://nix.dev/manual/nix/2.35/language/operators.html#comparison)                | *expr* `<` *expr*                          | none          | 10         |
| [Less than or equal to](https://nix.dev/manual/nix/2.35/language/operators.html#comparison)    | *expr* `<=` *expr*                         | none          | 10         |
| [Greater than](https://nix.dev/manual/nix/2.35/language/operators.html#comparison)             | *expr* `>` *expr*                          | none          | 10         |
| [Greater than or equal to](https://nix.dev/manual/nix/2.35/language/operators.html#comparison) | *expr* `>=` *expr*                         | none          | 10         |
| [Equality](https://nix.dev/manual/nix/2.35/language/operators.html#equality)                             | *expr* `==` *expr*                         | none          | 11         |
| Inequality                             | *expr* `!=` *expr*                         | none          | 11         |
| [Logical conjunction](https://nix.dev/manual/nix/2.35/language/operators.html#logical-conjunction) (`AND`)          | *bool* `&&` *bool*                         | left          | [12](https://nix.dev/manual/nix/2.35/language/operators.html#precedence-and-disjunctive-normal-form)         |
| [Logical disjunction](https://nix.dev/manual/nix/2.35/language/operators.html#logical-disjunction) (`OR`)           | *bool* <code>\|\|</code> *bool*            | left          | [13](https://nix.dev/manual/nix/2.35/language/operators.html#precedence-and-disjunctive-normal-form)         |
| [Logical implication](https://nix.dev/manual/nix/2.35/language/operators.html#logical-implication)                  | *bool* `->` *bool*                         | right         | 14         |
| [Pipe operator](https://nix.dev/manual/nix/2.35/language/operators.html#pipe-operators) (experimental)         | *expr* `\|>` *func*                        | left          | 15         |
| [Pipe operator](https://nix.dev/manual/nix/2.35/language/operators.html#pipe-operators) (experimental)         | *func* `<\|` *expr*                        | right         | 15         |


<!-- TODO(@rhendric, #10970): ^ rationalize number -> int/float -->

<a id="section-10"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/operators.md)

## Update

> **Syntax**
>
> *attrset1* // *attrset2*

Update [attribute set](https://nix.dev/manual/nix/2.35/language/types.html#type-attrs) *attrset1* with names and values from *attrset2*.

The returned attribute set will have all of the attributes in *attrset1* and *attrset2*.
If an attribute name is present in both, the attribute value from the latter is taken.

This operator is [strict](https://nix.dev/manual/nix/2.35/language/evaluation.html#strictness) in both *attrset1* and *attrset2*.
That means that both arguments are evaluated to [weak head normal form](https://nix.dev/manual/nix/2.35/language/evaluation.html#values), so the attribute sets themselves are evaluated, but their attribute values are not evaluated.


<a id="section-11"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/scope.md)

# Scoping rules

A *scope* in the Nix language is a dictionary keyed by [name](https://nix.dev/manual/nix/2.35/language/identifiers.html#names), mapping each name to an expression and a *definition type*.
The definition type is either *explicit* or *implicit*.
Each entry in this dictionary is a *definition*.

Explicit definitions are created by the following expressions:
- [let-expressions](https://nix.dev/manual/nix/2.35/language/syntax.html#let-expressions)
- [recursive attribute set literals](https://nix.dev/manual/nix/2.35/language/syntax.html#recursive-sets) (`rec`)
- [function literals](https://nix.dev/manual/nix/2.35/language/syntax.html#functions)

Implicit definitions are only created by [with-expressions](https://nix.dev/manual/nix/2.35/language/syntax.html#with-expressions).

Every expression is *enclosed* by a scope.
The outermost expression is enclosed by the [built-in, global scope](https://nix.dev/manual/nix/2.35/language/builtins.html), which contains only explicit definitions.
The expressions listed above *extend* their enclosing scope by adding new definitions, or replacing existing ones with the same name.
An explicit definition can replace a definition of any type; an implicit definition can only replace another implicit definition.

Each of the above expressions defines which of its subexpressions are enclosed by the extended scope.
In all other cases, the same scope that encloses an expression is the enclosing scope for its subexpressions.

The Nix language is [statically scoped](https://en.wikipedia.org/wiki/Scope_(computer_science)#Lexical_scope);
the value of a variable is determined only by the variable's enclosing scope, and not by the dynamic context in which the variable is evaluated.

> **Note**
>
> Expressions entered into the [Nix REPL](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-repl.html) are enclosed by a scope that can be extended by command line arguments or previous REPL commands.
> These ways of extending scope are not, strictly speaking, part of the Nix language.

<a id="section-12"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/evaluation.md)

## Laziness and thunks <a id="laziness"></a>

The Nix language implements _call by need_ (as opposed to _call by value_ or _call by reference_). <!-- No wikipedia link, which would be a huge distraction. --> Call by need is commonly known as laziness in functional programming, as it is a specific implementation of the concept where evaluation is deferred until the result is required, aiming to only evaluate the parts of an expression that are needed to produce the final result.

Furthermore, the result of evaluation is preserved, in values, in `let` bindings, in function _parameters_, which behave a lot like `let` bindings, but with the notable exception of function _calls_. Results of function calls rely on being put into `let` bindings, etc to be reused. <!-- which would be prohibitively expensive and too strict, or we wouldn't have a cache key for the argument -->

When discussing the process of evaluation in lower level terms, we may define values not as a subset of expressions, but separately, where each "value" is either a data constructor, a function or a _thunk_. A thunk is a delayed computation, represented by an expression reference and a "closure" &ndash; the values for the lexical scope around the delayed expression.

As a user of the language, you generally don't have to think about thunks, as they are not part of the language semantics, but you may encounter them in the repl, in the [C API](https://nix.dev/manual/nix/2.35/c-api.html) or in discussions.

<a id="section-13"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/evaluation.md)

## Strictness

Instead of thinking about thunks, it is often more productive to think in terms of _strictness_.
This term is used in functional programming to refer to the opposite of laziness, i.e. not just for something like error propagation. It refers to the need to evaluate certain expressions before evaluation can produce any result.

Statements about strictness usually implicitly refer to weak head normal form.
For example, we can say that the following function is strict in its argument:

```nix
x: isAttrs x || isFunction x
```

The above function must be strict in its argument `x` because determining its type requires evaluating `x` to at least some degree.

The following function is not strict in its argument:

```nix
x: { isOk = isAttrs x || isFunction x; }
```

It is not strict, because it can return the attribute set before evaluating `x`.
The attribute value for `isOk` _is_ strict in `x`.

A function with a _set pattern_ is always strict in its argument, as a consequence of checking the argument's type and/or attribute names:

```nix
let f = { ... }: "ok";
in f (throw "kablam")
=> error: kablam
```

However, a set pattern does not add any strictness beyond WHNF of the attribute set argument.

```nix
let f = orig@{ x, ... }: "ok";
in f { x = throw "error"; y = throw "error"; }
=> "ok"
```

<a id="section-14"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/string-literals.md)

# String literals

A *string literal* represents a [string](https://nix.dev/manual/nix/2.35/language/types.html#type-string) value.

> **Syntax**
>
> *expression* → *string*
>
> *string* → `"` ( *string_char*\* [*interpolation_element*](https://nix.dev/manual/nix/2.35/language/string-interpolation.html) )* *string_char*\* `"`
>
> *string* → `''` ( *indented_string_char*\* [*interpolation_element*](https://nix.dev/manual/nix/2.35/language/string-interpolation.html) )* *indented_string_char*\* `''`
>
> *string* → *uri*
>
> *string_char* ~ `[^"$\\]|\$(?!\{)|\\.`
>
> *indented_string_char* ~ `[^$']|\$\$|\$(?!\{)|''[$']|''\\.|'(?!')`
>
> *uri* ~ `[A-Za-z][+\-.0-9A-Za-z]*:[!$%&'*+,\-./0-9:=?@A-Z_a-z~]+`

Strings can be written in three ways.

The most common way is to enclose the string between double quotes, e.g., `"foo bar"`.
Strings can span multiple lines.
The results of other expressions can be included into a string by enclosing them in `${ }`, a feature known as [string interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html).


The following must be escaped to represent them within a string, by prefixing with a backslash (`\`):

- Double quote (`"`)

> **Example**
>
> ```nix
> "\""
> ```
>
>     "\""

- Backslash (`\`)

> **Example**
>
> ```nix
> "\\"
> ```
>
>     "\\"

- Dollar sign followed by an opening curly bracket (`${`) – "dollar-curly"

> **Example**
>
> ```nix
> "\${"
> ```
>
>     "\${"

The newline, carriage return, and tab characters can be written as `\n`, `\r` and `\t`, respectively.

A "double-dollar-curly" (`$${`) can be written literally.

> **Example**
>
> ```nix
> "$${"
> ```
>
>     "$\${"

String values are output on the terminal with Nix-specific escaping.
Strings written to files will contain the characters encoded by the escaping.

The second way to write string literals is as an *indented string*, which is enclosed between pairs of *double single-quotes* (`''`), like so:

```nix
''
This is the first line.
This is the second line.
  This is the third line.
''
```

This kind of string literal intelligently strips indentation from
the start of each line. To be precise, it strips from each line a
number of spaces equal to the minimal indentation of the string as a
whole (disregarding the indentation of empty lines). For instance,
the first and second line are indented two spaces, while the third
line is indented four spaces. Thus, two spaces are stripped from
each line, so the resulting string is

```nix
"This is the first line.\nThis is the second line.\n  This is the third line.\n"
```

> **Note**
>
> Whitespace and newline following the opening `''` is ignored if there is no non-whitespace text on the initial line.

> **Warning**
>
> Prefixed tab characters are not stripped.
>
> > **Example**
> >
> > The following indented string is prefixed with tabs:
> >
> > <pre><code class="nohighlight">''
> > 	all:
> > 		@echo hello
> > ''
> > </code></pre>
> >
> >     "\tall:\n\t\t@echo hello\n"

Indented strings support [string interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html).

The following must be escaped to represent them in an indented string:

- `$` is escaped by prefixing it with two single quotes (`''`)

> **Example**
>
> ```nix
> ''
>   ''$
> ''
> ```
>
>     "$\n"

- `''` is escaped by prefixing it with one single quote (`'`)

> **Example**
>
> ```nix
> ''
>   '''
> ''
> ```
>
>     "''\n"

These special characters are escaped as follows:
- Linefeed (`\n`): `''\n`
- Carriage return (`\r`): `''\r`
- Tab (`\t`): `''\t`

`''\` escapes any other character.

A "dollar-curly" (`${`) can be written as follows:
> **Example**
>
> ```nix
> ''
>   echo ''${PATH}
> ''
> ```
>
>     "echo ${PATH}\n"

> **Note**
>
> This differs from the syntax for escaping a dollar-curly within double quotes (`"\${"`). Be aware of which one is needed at a given moment.

A "double-dollar-curly" (`$${`) can be written literally.

> **Example**
>
> ```nix
> ''
>   $${
> ''
> ```
>
>     "$\${\n"

Indented strings are primarily useful in that they allow multi-line
string literals to follow the indentation of the enclosing Nix
expression, and that less escaping is typically necessary for
strings representing languages such as shell scripts and
configuration files because `''` is much less common than `"`.
Example:

```nix
stdenv.mkDerivation {
...
postInstall =
  ''
    mkdir $out/bin $out/etc
    cp foo $out/bin
    echo "Hello World" > $out/etc/foo.conf
    ${if enableBar then "cp bar $out/bin" else ""}
  '';
...
}
```

Finally, as a convenience, *URIs* as defined in appendix B of
[RFC 2396](http://www.ietf.org/rfc/rfc2396.txt) can be written *as
is*, without quotes. For instance, the string
`"http://example.org/foo.tar.bz2"` can also be written as
`http://example.org/foo.tar.bz2`.

<a id="section-15"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/string-interpolation.md)

# Interpolated expression

An expression that is interpolated must evaluate to one of the following:

- a [string](https://nix.dev/manual/nix/2.35/language/types.html#type-string)
- a [path](https://nix.dev/manual/nix/2.35/language/types.html#type-path)
- an [attribute set](https://nix.dev/manual/nix/2.35/language/types.html#type-attrs) that has a `__toString` attribute or an `outPath` attribute

  - `__toString` must be a function that takes the attribute set itself and returns a string
  - `outPath` must be a string

  This includes [derivation expressions](https://nix.dev/manual/nix/2.35/language/derivations.html) or [flake inputs](https://nix.dev/manual/nix/2.35/command-ref/new-cli/nix3-flake.html#flake-inputs) (experimental).

A string interpolates to itself.

A path in an interpolated expression is first copied into the Nix store, and the resulting string is the [store path](https://nix.dev/manual/nix/2.35/store/store-path.html) of the newly created [store object](https://nix.dev/manual/nix/2.35/store/store-object.html).


> **Example**
>
> ```console
> $ mkdir foo
> ```
>
> Reference the empty directory in an interpolated expression:
>
> ```nix
> "${./foo}"
> ```
>
>     "/nix/store/2hhl2nz5v0khbn06ys82nrk99aa1xxdw-foo"

A derivation interpolates to the [store path](https://nix.dev/manual/nix/2.35/store/store-path.html) of its first [output](https://nix.dev/manual/nix/2.35/language/derivations.html#attr-outputs).

> **Example**
>
> ```nix
> let
>   pkgs = import <nixpkgs> {};
> in
> "${pkgs.hello}"
> ```
>
>     "/nix/store/qnlr7906z0mrl2syrkdbpicffq02nw07-hello-2.12.1"

An attribute set interpolates to the return value of the function in the `__toString` applied to the attribute set itself.

> **Example**
>
> ```nix
> let
>   a = {
>     value = 1;
>     __toString = self: toString (self.value + 1);
>   };
> in
> "${a}"
> ```
>
>     "2"

An attribute set also interpolates to the value of its `outPath` attribute.

> **Example**
>
> ```nix
> let
>   a = { outPath = "foo"; };
> in
> "${a}"
> ```
>
>     "foo"

If both `__toString` and `outPath` are present in an attribute set, `__toString` takes precedence.

> **Example**
>
> ```nix
> let
>   a = { __toString = _: "yes"; outPath = throw "no"; };
> in
> "${a}"
> ```
>
>     "yes"

If neither is present, an error is thrown.

> **Example**
>
> ```nix
> let
>   a = {};
> in
> "${a}"
> ```
>
>     error: cannot coerce a set to a string: { }
>
>            at «string»:4:2:
>
>                 3| in
>                 4| "${a}"
>                  |  ^

<a id="section-16"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/string-context.md)

# String context

> **Note**
>
> This is an advanced topic.
> The Nix language is designed to be used without the programmer consciously dealing with string contexts or even knowing what they are.

A string in the Nix language is not just a sequence of characters like strings in other languages.
It is actually a pair of a sequence of characters and a *string context*.
The string context is an (unordered) set of *string context elements*.

The purpose of string contexts is to collect non-string values attached to strings via
[string concatenation](https://nix.dev/manual/nix/2.35/language/operators.html#string-concatenation),
[string interpolation](https://nix.dev/manual/nix/2.35/language/string-interpolation.html),
and similar operations.
The idea is that a user can reference other files when creating text files through Nix expressions, without manually keeping track of the exact paths.
Nix will ensure that the all referenced files are accessible – that all [store paths](https://nix.dev/manual/nix/2.35/glossary.html#gloss-store-path) are [valid](https://nix.dev/manual/nix/2.35/glossary.html#gloss-validity).

> **Note**
>
> String contexts are *not* explicitly manipulated in idiomatic Nix language code.

String context elements come in different forms:

- [deriving path](https://nix.dev/manual/nix/2.35/glossary.html#gloss-deriving-path)<a id="string-context-element-derived-path"></a>

  A string context element of this type is a [deriving path](https://nix.dev/manual/nix/2.35/glossary.html#gloss-deriving-path).
  They can be either of type [constant](https://nix.dev/manual/nix/2.35/language/string-context.html#string-context-constant) or [output](https://nix.dev/manual/nix/2.35/language/string-context.html#string-context-output), which correspond to the types of deriving paths.

  - [Constant string context elements]<a id="string-context-constant"></a>

    > **Example**
    >
    > [`builtins.storePath`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-storePath) creates a string with a single constant string context element:
    >
    > ```nix
    > builtins.getContext (builtins.storePath "/nix/store/ikwkxz4wwlp2g1428n7dy729cg1d9hin-hello-2.10")
    > ```
    > evaluates to
    > ```nix
    > {
    >   "/nix/store/ikwkxz4wwlp2g1428n7dy729cg1d9hin-hello-2.10" = {
    >     path = true;
    >   };
    > }
    > ```


  - [Output string context elements]<a id="string-context-output"></a>

    > **Example**
    >
    > The behavior of string contexts are best demonstrated with a built-in function that is still experimental: [`builtins.outputOf`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-outputOf).
    > This example will *not* work with stable Nix!
    >
    > ```nix
    > builtins.getContext
    >   (builtins.outputOf
    >     (builtins.storePath "/nix/store/fvchh9cvcr7kdla6n860hshchsba305w-hello-2.12.drv")
    >     "out")
    > ```
    > evaluates to
    > ```nix
    > {
    >   "/nix/store/fvchh9cvcr7kdla6n860hshchsba305w-hello-2.12.drv" = {
    >     outputs = [ "out" ];
    >   };
    > }
    > ```


- [*derivation deep*]<a id="string-context-element-derivation-deep"></a>

  *derivation deep* is an advanced feature intended to be used with the
  [`exportReferencesGraph` derivation attribute](https://nix.dev/manual/nix/2.35/language/advanced-attributes.html#adv-attr-exportReferencesGraph).
  A *derivation deep* string context element is a derivation path, and refers to both its outputs and the entire build closure of that derivation:
  all its outputs, all the other derivations the given derivation depends on, and all the outputs of those.

  > **Example**
  >
  > The best way to illustrate *derivation deep* string contexts is with [`builtins.addDrvOutputDependencies`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-addDrvOutputDependencies).
  > Take a regular constant string context element pointing to a derivation, and transform it into a "Derivation deep" string context element.
  >
  > ```nix
  > builtins.getContext
  >   (builtins.addDrvOutputDependencies
  >     (builtins.storePath "/nix/store/fvchh9cvcr7kdla6n860hshchsba305w-hello-2.12.drv"))
  > ```
  > evaluates to
  > ```nix
  > {
  >   "/nix/store/fvchh9cvcr7kdla6n860hshchsba305w-hello-2.12.drv" = {
  >     allOutputs = true;
  >   };
  > }
  > ```


<a id="section-17"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/string-context.md)

## Inspecting string contexts

Most basically, [`builtins.hasContext`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-hasContext) will tell whether a string has a non-empty context.

When more granular information is needed, [`builtins.getContext`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-getContext) can be used.
It creates an [attribute set](https://nix.dev/manual/nix/2.35/language/types.html#type-attrs) representing the string context, which can be inspected as usual.


<a id="section-18"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/string-context.md)

## Clearing string contexts

[`builtins.unsafeDiscardStringContext`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-unsafeDiscardStringContext) will make a copy of a string, but with an empty string context.
The returned string can be used in more ways, e.g. by operators that require the string context to be empty.
The requirement to explicitly discard the string context in such use cases helps ensure that string context elements are not lost by mistake.
The "unsafe" marker is only there to remind that Nix normally guarantees that dependencies are tracked, whereas the returned string has lost them.

<a id="section-19"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/derivations.md)

# Derivations

The most important built-in function is `derivation`, which is used to describe a single store-layer [store derivation](https://nix.dev/manual/nix/2.35/glossary.html#gloss-store-derivation).
Consult the [store chapter](https://nix.dev/manual/nix/2.35/store/derivation/index.html) for what a store derivation is;
this section just concerns how to create one from the Nix language.

This builtin function takes as input an attribute set, the attributes of which specify the inputs to the process.
It outputs an attribute set, and produces a [store derivation](https://nix.dev/manual/nix/2.35/glossary.html#gloss-store-derivation) as a side effect of evaluation.


<a id="section-20"></a>

[Upstream source](https://github.com/NixOS/nix/blob/2c73b59da29606068c0c98db015dd3a66955525d/doc/manual/source/language/derivations.md)

### Required

- [`name`]<a id="attr-name"></a> ([String](https://nix.dev/manual/nix/2.35/language/types.html#type-string))

  A symbolic name for the derivation.
  See [derivation outputs](https://nix.dev/manual/nix/2.35/store/derivation/outputs/index.html#outputs) for what this is affects.


  > **Example**
  >
  > ```nix
  > derivation {
  >   name = "hello";
  >   # ...
  > }
  > ```
  >
  > The derivation's path will be `/nix/store/<hash>-hello.drv`.
  > The [output](https://nix.dev/manual/nix/2.35/language/derivations.html#attr-outputs) paths will be of the form `/nix/store/<hash>-hello[-<output>]`

- [`system`]<a id="attr-system"></a> ([String](https://nix.dev/manual/nix/2.35/language/types.html#type-string))

  See [system](https://nix.dev/manual/nix/2.35/store/derivation/index.html#system).

  > **Example**
  >
  > Declare a derivation to be built on a specific system type:
  >
  > ```nix
  > derivation {
  >   # ...
  >   system = "x86_64-linux";
  >   # ...
  > }
  > ```

  > **Example**
  >
  > Declare a derivation to be built on the system type that evaluates the expression:
  >
  > ```nix
  > derivation {
  >   # ...
  >   system = builtins.currentSystem;
  >   # ...
  > }
  > ```
  >
  > [`builtins.currentSystem`](https://nix.dev/manual/nix/2.35/language/builtins.html#builtins-currentSystem) has the value of the [`system` configuration option](https://nix.dev/manual/nix/2.35/command-ref/conf-file.html#conf-system), and defaults to the system type of the current Nix installation.

- [`builder`]<a id="attr-builder"></a> ([Path](https://nix.dev/manual/nix/2.35/language/types.html#type-path) | [String](https://nix.dev/manual/nix/2.35/language/types.html#type-string))

  See [builder](https://nix.dev/manual/nix/2.35/store/derivation/index.html#builder).

  > **Example**
  >
  > Use the file located at `/bin/bash` as the builder executable:
  >
  > ```nix
  > derivation {
  >   # ...
  >   builder = "/bin/bash";
  >   # ...
  > };
  > ```

  <!-- -->

  > **Example**
  >
  > Copy a local file to the Nix store for use as the builder executable:
  >
  > ```nix
  > derivation {
  >   # ...
  >   builder = ./builder.sh;
  >   # ...
  > };
  > ```

  <!-- -->

  > **Example**
  >
  > Use a file from another derivation as the builder executable:
  >
  > ```nix
  > let pkgs = import <nixpkgs> {}; in
  > derivation {
  >   # ...
  >   builder = "${pkgs.python}/bin/python";
  >   # ...
  > };
  > ```
