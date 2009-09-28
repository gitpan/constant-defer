# Copyright 2008, 2009 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# constant-defer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.

package constant::defer;
use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 1;

sub import {
  my $class = shift;
  $class->_create_for_package (scalar(caller), @_);
}
sub _create_for_package {
  my $class = shift;
  my $target_package = shift;
  while (@_) {
    my $name = shift;
    if (ref $name eq 'HASH') {
      unshift @_, %$name;
      next;
    }
    unless (@_) {
      require Carp;
      Carp::croak ("Missing value sub for $name");
    }
    my $subr = shift;

    ### $constant::defer::DEBUG_LAST_SUBR = $subr;

    my ($fullname, $basename);
    if ($name =~ /::([^:]*)$/s) {
      $fullname = $name;
      $basename = $1;
    } else {
      $basename = $name;
      $fullname = "${target_package}::$name";
    }
    ## print "constant::defer $arg -- $fullname $basename $old\n";
    $class->_validate_name ($basename);
    $class->_create_fullname ($fullname, $subr);
  }
}

sub _create_fullname {
  my ($class, $fullname, $subr) = @_;
  my $run;
  $run = sub {
    unshift @_, $fullname, $subr, \$run;
    goto &_run
  };
  my $func = sub () { goto $run };
  no strict 'refs';
  *$fullname = $func;
}

sub _run {
  my $fullname = shift;
  my $subr = shift;
  my $run_ref = shift;
  ### print "_run() $fullname $subr\n";

  my @ret = $subr->(@_);
  if (@ret == 1) {
    # constant.pm has an optimization to make a constant by storing a scalar
    # value directly into the %{Foo::Bar::} hash if there's no typeglob for
    # the name yet.  But that doesn't apply here, there's always a glob
    # having converted a function.
    #
    my $value = $ret[0];
    $subr = sub () { $value };

  } elsif (@ret == 0) {
    $subr = \&_nothing;

  } else {
    $subr = sub () { @ret };
  }

  $$run_ref = $subr;
  { no warnings 'redefine';
    no strict 'refs';
    *$fullname = $subr;
  }
  goto $subr;
}

# not as strict as constant.pm
sub _validate_name {
  my ($class, $name) = @_;
  if ($name =~ m{[()]   # no parens like CODE(0x1234) if miscounted args
               |^[0-9]  # no starting with a number
               |^$      # not empty
              }x) {
    require Carp;
    Carp::croak ("Constant name '$name' is invalid");
  }
}

sub _nothing () { }

1;
__END__

=head1 NAME

constant::defer -- constant subs with deferred value calculation

=head1 SYNOPSIS

 use constant::defer FOO => sub { return $some + $thing; },
                     BAR => sub { return $an * $other; };

 use constant::defer MYOBJ => sub { require My::Class;
                                    return My::Class->new_thing; }

=head1 DESCRIPTION

C<constant::defer> creates a subroutine which runs given code to calculate
its value on the first call, and from then on returns just that value, like
a constant.  The value code is discarded once run, allowing it to be garbage
collected.

Deferring a calculation is good if it might take a lot of work and/or
produce a big result, yet is only needed sometimes or only well into a
program run.  If it's never needed then the code never runs.

Here are some typical uses.

=over 4

=item *

A big value or slow calculation put off,

    use constant::defer SLOWVALUE => sub {
                          long calculation ...;
                          return $result;
                        };
    if ($option) {
      print "s=", SLOWVALUE, "\n";
    }

=item *

A shared object instance created when needed then re-used,

    use constant::defer FORMATTER
      => sub { return My::Formatter->new };
    if ($something) {
      FORMATTER()->format ...
    }

=item *

The value code might load requisite modules too, again deferring that until
actually needed,

    use constant::defer big => sub {
      require Some::Big::Module;
      return Some::Big::Module->create_something(...);
    };

=item *

Once-only setup code can be created with no return value.  The code is
garbage collected after the first run and becomes a do-nothing.  Remember to
have an empty return statement so as not to keep the last statement's value
alive forever.

    use constant::defer MY_INIT => sub {
      many lines of setup code ...;
      return;
    };

    sub new {
      MY_INIT();
      ...
    }

=back

=head1 IMPORTS

There are no functions as such, everything is accomplished through the
C<use> import.

=over 4

=item C<< use constant::defer NAME1=>SUB1, NAME2=>SUB2, ...; >>

The parameters are name/subroutine pairs.  For each a sub called C<NAME> is
created, running the C<SUB> the first time its value is needed.

C<NAME> defaults to the caller's package, or a fully qualified name can be
given.  Remember that the bareword stringizing of C<=E<gt>> doesn't act on a
qualified name, so add quotes in that case.

    use constant::defer 'Other::Package::BAR' => sub { ... };

For compatibility with the C<constant> module a hash of name/sub arguments
is accepted too.  But this is not needed with C<constant::defer> since
there's only ever one thing (a sub) following the name.

    use constant::defer { FOO => sub { ... },
                          BAR => sub { ... } };

=back

=head1 MULTIPLE VALUES

The value sub can return multiple values to make an array style constant
sub.

    use constant::defer NUMS => sub { return ('one', 'two') };

    foreach (NUMS) {
       print $_,"\n";
    }

The value sub is always run in array context, for consistency, irrespective
how the constant is used.  For zero or one return values this makes no
difference.  But for two or more any list return in the value sub becomes an
array return from the constant like

    sub () { return @result }

List versus array return are subtly different in scalar context; a list
gives the last value like a comma operator, an array gives the number of
elements.  The array style is easier to implement for C<constant::defer> and
is the same as the plain C<constant> module does.

=head1 ARGUMENTS

If the constant sub is called with arguments then they're passed on to the
value sub.  This can be good for constants used as object or class methods,
but anything else to plain constants would be unusual.

One cute use for class method style is to make a "singleton" instance of a
class.  See F<examples/instance.pl> in the source for a complete program.

    package My::Class;
    use constant::defer INSTANCE => sub { my ($class) = @_;
                                          return $class->new };
    package main;
    $obj = My::Class->INSTANCE;

Subs created by C<constant::defer> always have prototype C<()>, ensuring
they always parse the same way.  The prototype has no effect when called as
a method like above, but if you want to pass arguments in a plain call then
use C<&> to bypass the prototype (see L<perlsub>).

    &MYCONST ('Some value');

=head1 IMPLEMENTATION

Currently C<constant::defer> creates sub under the requested name and when
called it replaces itself with a new constant sub the same as C<use
constant> would make.  This is compact and means that later C<require>d code
might be able to inline the value.

It's fine to keep a reference to the initial sub and in fact that happens
quite normally if imported into another modules (with the usual
C<Exporter>), or an explicit C<\&foo>, or a C<$package-E<gt>can('foo')>.
The initial sub changes itself to jump to the new constant, it doesn't
re-run the value code.

The jump is currently done by a C<goto> of a scalar, so it's a touch slower
than the new constant sub directly.  A spot of XS would no doubt make the
difference negligible, and in fact probably to the point where there'd be no
need for a new sub, just have the initial transform itself.

=head1 OTHER WAYS

There's more than one way to do "deferred" or "lazy" calculations.  In fact
there's a lot of ways.

=over 4

=item *

C<Memoize> makes a function repeat its return.  It caches results against
different arguments, so it preserves the original code whereas
C<constant::defer> discards after the first run.

=item *

C<Class::Singleton> and friends make a create-once
C<My::Class-E<gt>instance> method.  C<constant::defer> can get close with
the fakery under L</ARGUMENTS> above, though without a C<has_instance> to
query.

=item *

A scalar can be rigged up to run code on its first access.  The advantage of
a variable is that it interpolates in strings, but it won't inline in later
loaded code, sloppy XS code might bypass the magic, and public package
variables aren't terribly friendly when subclassing.

Modules for this include: C<Data::Lazy> using a C<tie>.  C<Scalar::Defer>
and C<Scalar::Lazy> using C<overload> on an object.  And C<Data::Thunk>
optimizing out the object from C<Scalar::Defer> after the first run.

=item *

C<Object::Lazy> and L<Object::Realize::Later> rig up an object to only load
its class and create itself when a method is called.  The advantage is you
can access the value, pass it around, etc, deferring to an even later point
than a sub or scalar.

=back

=head1 SEE ALSO

L<constant>, L<perlsub>

L<Memoize>, L<Attribute::Memoize>, L<Memoize::Attrs>, L<Class::Singleton>,
L<Data::Lazy>, L<Scalar::Defer>, L<Scalar::Lazy>, L<Data::Thunk>,
L<Object::Lazy> L<Object::Realize::Later>

=head1 HOME PAGE

http://user42.tuxfamily.org/constant-defer/index.html

=head1 COPYRIGHT

Copyright 2009 Kevin Ryde

constant-defer is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

constant-defer is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
constant-defer.  If not, see <http://www.gnu.org/licenses/>.

=cut
