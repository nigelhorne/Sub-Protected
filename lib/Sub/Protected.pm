package Sub::Protected;

use strict;
use warnings;
use 5.008;

use Carp qw(croak);
use Attribute::Handlers;

our $VERSION = '0.01';
our $BYPASS  = 0;
our @_pending;

# Install :Protected in UNIVERSAL so every package can use it after loading this module.
sub UNIVERSAL::Protected : ATTR(CODE,CHECK) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    my $sub_name = *{$symbol}{NAME};
    no warnings 'redefine';
    *{$symbol} = Sub::Protected::_wrap($package, $sub_name, $referent);
}

sub import {
    my ($class, @subs) = @_;
    return unless @subs;
    my $owner_pkg = caller;
    push @_pending, [$owner_pkg, $_] for @subs;
}

# Process declarative-form wraps scheduled by import().
CHECK {
    no strict 'refs';
    for my $entry (@_pending) {
        my ($owner_pkg, $sub_name) = @$entry;
        croak "Sub::Protected: ${owner_pkg}::${sub_name} is not defined"
            unless defined &{"${owner_pkg}::${sub_name}"};
        my $code = \&{"${owner_pkg}::${sub_name}"};
        no warnings 'redefine';
        *{"${owner_pkg}::${sub_name}"} = _wrap($owner_pkg, $sub_name, $code);
    }
    @_pending = ();
}

sub _wrap {
    my ($owner_pkg, $sub_name, $code) = @_;
    return sub {
        Sub::Protected::_check_access($owner_pkg, $sub_name);
        goto &$code;
    };
}

sub _check_access {
    my ($owner_pkg, $sub_name) = @_;
    return if $BYPASS || $ENV{HARNESS_ACTIVE};
    my $i = 0;
    while (1) {
        my $pkg = (caller($i))[0];
        if (!defined $pkg) {
            croak "${sub_name}() is a protected method of ${owner_pkg} and cannot be called from outside";
        }
        if ($pkg eq 'Sub::Protected') {
            $i++;
            next;
        }
        if ($pkg eq $owner_pkg || $pkg->isa($owner_pkg)) {
            return;
        }
        croak "${sub_name}() is a protected method of ${owner_pkg} and cannot be called from ${pkg}";
    }
}

1;

__END__

=head1 NAME

Sub::Protected - enforce protected subroutine access

=head1 VERSION

0.01

=head1 SYNOPSIS

    package Foo;
    use Sub::Protected;

    sub new { bless {}, shift }

    # Attribute form (preferred)
    sub _helper :Protected {
        ...
    }

    # Or declarative form
    package Bar;
    use Sub::Protected qw(_other);
    sub _other { ... }

=head1 DESCRIPTION

Enforces Java/C++-style "protected" access: a subroutine may be called
from within the defining package and its subclasses, but not from
arbitrary external callers.  Violations croak with a descriptive message.

=head2 Two usage forms

=over 4

=item Attribute form (preferred)

    sub _helper :Protected { ... }

Wraps the sub at CHECK time via L<Attribute::Handlers>.

=item Declarative form

    use Sub::Protected qw(_helper _other);

Wraps the named subs at CHECK time.  The subs must be defined before CHECK
fires (i.e. they must be regular named subs in the same file, not generated
at runtime).

=back

=head2 Bypass for testing

Either of the following (OR logic) disables all checks:

=over 4

=item *

C<$Sub::Protected::BYPASS> set to a true value.  Use C<local> in tests.

=item *

C<$ENV{HARNESS_ACTIVE}> set (the convention set by L<Test::Harness>/prove).

=back

C<$Sub::Protected::BYPASS> is the recommended explicit form for new test code.
C<HARNESS_ACTIVE> is a zero-config convenience.

=head2 Error message format

    _helper() is a protected method of Foo and cannot be called from Bar

=head1 KNOWN LIMITATIONS

=over 4

=item *

Checks are runtime only; there is no compile-time enforcement.

=item *

A raw code reference obtained before wrapping (via C<can()> or direct
C<\&Foo::_helper>) bypasses the check.  The attribute form prevents this
since wrapping happens at compile time.

=item *

Moo/Moose method modifiers applied after Sub::Protected has wrapped a sub
will wrap the wrapper.  Apply Sub::Protected last, or use the declarative
form in a CHECK block after the class is fully built.

=back

=head1 DEPENDENCIES

L<Carp>, L<Attribute::Handlers> (core since 5.8).

=head1 AUTHOR

Nigel Horne

=head1 LICENSE

Same as Perl itself.

=cut
