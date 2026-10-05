## Name

Sub::Protected - Enforce protected subroutine access (Java/C++ semantics)

## Version

0.02

## Synopsis

```perl
package Foo;
use Sub::Protected;              # enables the :Protected attribute

sub new { bless {}, shift }

# Attribute form (preferred: protection lives next to the definition)
sub _helper :Protected {
    ...
}

sub public_method {
    my $self = shift;
    $self->_helper;              # OK -- same package
}

# ----------------------------------------------------------------

package Bar;
use Sub::Protected qw(_other _private);   # declarative form

sub _other   { 'other'   }
sub _private { 'private' }
```

## Description

Enforces Java/C++-style "protected" access at runtime: a subroutine
decorated with `:Protected` (or named in `use Sub::Protected qw(...)`)
may only be called from within its defining package or from a subclass of
that package.  Any other caller causes a `Carp::croak` with a descriptive
message.

### Two Usage Forms

- Attribute form (preferred)

    ```perl
    sub _helper :Protected { ... }
    ```

    The `:Protected` attribute is registered in `UNIVERSAL` via
    [Attribute::Handlers](https://metacpan.org/pod/Attribute%3A%3AHandlers) when `Sub::Protected` is loaded, so every package
    has access to it without any further `use` or inheritance.  The sub is
    wrapped at `CHECK` time, or, if the module is loaded after `CHECK` (Perl
    5.14 or later), at the end of the file being compiled.  This form is preferred because the protection
    declaration sits next to the definition and wrapping happens at compile time
    (making pre-wrap raw-coderef captures impossible).

- Declarative form

    ```perl
    use Sub::Protected qw(_helper _other);
    ```

    Each named sub is looked up in the caller's stash and wrapped at `CHECK`
    time (or immediately if the module is loaded at runtime via `require`).
    All named subs must be defined before `CHECK` fires -- i.e. they must be
    compile-time named subs in the same file, not generated at runtime.

### Bypass for Testing

Either condition alone (OR logic) disables all access checks:

- `$Sub::Protected::BYPASS` set to a true value.  Use `local` in tests.
- `$ENV{HARNESS_ACTIVE}` set (the convention used by [Test::Harness](https://metacpan.org/pod/Test%3A%3AHarness)/prove).

`$Sub::Protected::BYPASS` is the recommended form for new test code;
it is explicit and does not depend on the test runner.
`HARNESS_ACTIVE` is a zero-config convenience.

The HARNESS\_ACTIVE bypass can be disabled by setting:

```
$Sub::Protected::config{harness_bypass} = 0;
```

### Configuration

The module exposes `%Sub::Protected::config` for runtime configuration:

- `harness_bypass` (default: 1)

    When true, access checks are skipped whenever `$ENV{HARNESS_ACTIVE}` is
    set.  Set to 0 to test protection behaviour from within a test harness.

The hash is compatible with [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) for dependency-injection
scenarios.

### Error Message Format

```
_helper() is a protected method of Foo and cannot be called from Bar
```

## Public Interface

### Import

```perl
use Sub::Protected;                    # attribute form -- no arguments
use Sub::Protected qw(_a _b _c);      # declarative form
```

#### Purpose

Called automatically by `use Sub::Protected`.

With **no arguments**: does nothing beyond making the `:Protected` attribute
globally available (which happens when the module is first loaded).

With **one or more sub names**: registers those subs in the calling
package for wrapping at `CHECK` time.  If `CHECK` has already fired
(e.g. the module was loaded via runtime `require`, a plugin loader or a
string `eval`), wrapping is applied immediately.
Each named sub must be defined before `CHECK` fires (for pre-CHECK loads)
or before `import` is called (for post-CHECK loads), so a module loaded at
run time should call `Sub::Protected->import(...)` at the end of the
file, after its subs are defined.

Run-time loading needs Perl 5.14 or later.  On older Perls the module must
be loaded at compile time (`use`, or `require` inside `BEGIN`).

#### Arguments

- `$class` (positional, required)

    The name of the importing class.  Set automatically by the `use` mechanism.
    Must be a non-empty string.

- `@subs` (positional, optional)

    Zero or more sub names to protect in the calling package.  Each must be a
    valid Perl identifier: matching `/\A[_a-zA-Z]\w*\z/`.

#### Returns

`$class` (the importing class name).  The return value is ignored by the
`use` mechanism; it is provided for optional method chaining at the class
level.

#### Side Effects

- Each supplied sub name is appended to an internal pending list (if pre-CHECK)
or wrapped immediately (if post-CHECK).
- The pending list is consumed and cleared when the CHECK block fires.

#### Example

```perl
package Foo;
use Sub::Protected qw(_helper _init);

sub _helper { ... }   # will be protected
sub _init   { ... }   # will be protected
```

#### Api Specification

##### Input

```perl
# Params::Get::get_params / Params::Validate::Strict schema
{
    # class is the implicit first argument, set by Perl's 'use' mechanism
    subs => {
        type     => 'array',
        required => 0,
        each     => {
            type  => 'string',
            regex => qr/\A[_a-zA-Z]\w*\z/,
        },
    },
}
```

##### Output

```perl
# Return::Set schema
{
    type    => 'string',
    desc    => 'The importing class name ($class), for optional chaining.',
}
```

#### Messages

The following table lists every error or warning this method can produce.

```perl
Message                                     Meaning
----------------------------------------    -------------------------------------
"Sub::Protected->import: 'NAME' is not a    A sub name passed to import() failed
 valid Perl identifier"                      the identifier regex.  Use a name
                                             matching /\A[_a-zA-Z]\w*\z/.

"Sub::Protected: PKG::NAME is not defined"  The named sub was not found in the
                                             package stash at wrap time.  For
                                             pre-CHECK loads, ensure the sub is
                                             a compile-time named sub.  For
                                             post-CHECK/runtime loads, ensure
                                             the sub is defined before import().
```

## Known Limitations

- Runtime-only

    Checks are runtime only; there is no compile-time enforcement.

- Raw coderef bypass

    A raw code reference obtained **before** wrapping (via `can()` or direct
    `\&Foo::_helper`) bypasses the check.  The attribute form prevents this
    because wrapping happens at compile time.

- Moo/Moose method modifiers

    Method modifiers applied after Sub::Protected has wrapped a sub will wrap
    the wrapper.  Apply Sub::Protected last, or use the declarative form in a
    `CHECK` block after the class is fully built.

- Run-time loading on Perl < 5.14

    On Perls older than 5.14, loading this module (or a package that uses it)
    at run time -- via `require`, a plugin loader or a string `eval` -- leaves
    the subs unprotected, because `CHECK` has already fired.  Load it at
    compile time instead.

- UNIVERSAL namespace pollution

    The `:Protected` attribute is installed in `UNIVERSAL`, which is
    intentional (any package can use it after a single `use`), but it does
    introduce `UNIVERSAL::Protected` into the global namespace.

- Thread safety

    `@_pending` and `$BYPASS` are unguarded package globals.  Do not use
    concurrent `use Sub::Protected qw(...)` calls across threads.

## Dependencies

[Carp](https://metacpan.org/pod/Carp) (core),
[Attribute::Handlers](https://metacpan.org/pod/Attribute%3A%3AHandlers) (core since 5.8),
[B::Hooks::EndOfScope](https://metacpan.org/pod/B%3A%3AHooks%3A%3AEndOfScope),
[Readonly](https://metacpan.org/pod/Readonly),
[Scalar::Util](https://metacpan.org/pod/Scalar%3A%3AUtil) (core),
[Sub::Identify](https://metacpan.org/pod/Sub%3A%3AIdentify),
[Params::Get](https://metacpan.org/pod/Params%3A%3AGet),
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict),
[Return::Set](https://metacpan.org/pod/Return%3A%3ASet).

## See Also

- [Test Dashboard](https://nigelhorne.github.io/Sub-Protected/coverage/)
- [Sub::Abstract](https://metacpan.org/pod/Sub%3A%3AAbstract)

    Sister module enforcing abstract (virtual) methods

- [Sub::Private](https://metacpan.org/pod/Sub%3A%3APrivate)

    Sister module enforcing strictly private (owner-only) access.

[Attribute::Handlers](https://metacpan.org/pod/Attribute%3A%3AHandlers), [Carp](https://metacpan.org/pod/Carp), [Readonly](https://metacpan.org/pod/Readonly), [Params::Get](https://metacpan.org/pod/Params%3A%3AGet),
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), [Return::Set](https://metacpan.org/pod/Return%3A%3ASet).

## Formal Specification

### Import

The following Z-notation schemas formally specify the state and operations
of Sub::Protected.  Unicode mathematical symbols are used in this section
only.

```perl
-- Type abbreviations
Package  == seq CHAR     -- a non-empty Perl package name string
SubName  == seq CHAR     -- a Perl identifier string
Proc     == seq CHAR     -- abstract: a callable code reference

-- Ancestry relation (derived dynamically from @ISA chains)
anc : Package -> P Package
forall p : Package .
    anc p = {p} union bigcup { anc r | r in @ISA_of(p) }

-- Protected-access predicate
permitted : Package x Package -> BOOL
forall caller, owner : Package .
    permitted(caller, owner) <=> owner in anc(caller)

-- System state
+-Registry-------------------------------------------+
| protected : P (Package x SubName)                  |
| bypass    : BOOL                                   |
| config    : { harness_bypass : BOOL }              |
+----------------------------------------------------+

-- Initial state
+-InitRegistry---------------------------------------+
| Registry                                           |
|----------------------------------------------------|
| protected = {}                                     |
| bypass    = false                                  |
| config    = { harness_bypass |-> true }            |
+----------------------------------------------------+

-- Wrap: add a sub to the protected registry
+-Wrap-----------------------------------------------+
| Delta-Registry                                     |
| pkg? : Package ; name? : SubName                   |
|----------------------------------------------------|
| protected' = protected union { (pkg?, name?) }     |
| bypass'    = bypass                                |
| config'    = config                                |
+----------------------------------------------------+

-- Bypass predicate
bypass_active(R) <=>
    R.bypass or (R.config.harness_bypass and HARNESS_ACTIVE)

-- Access check: no state change
+-CheckAccess----------------------------------------+
| Xi-Registry                                        |
| caller? : Package                                  |
| owner?  : Package                                  |
| name?   : SubName                                  |
| ok!     : BOOL                                     |
|----------------------------------------------------|
| (owner?, name?) in protected                       |
| ok! <=> bypass_active or permitted(caller?, owner?)|
+----------------------------------------------------+

-- Violation (croak case):
--   not ok! =>
--   croak("name?()" ++ " is a protected method of " ++ owner?
--         ++ " and cannot be called from " ++ caller?)
```

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Licence and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
