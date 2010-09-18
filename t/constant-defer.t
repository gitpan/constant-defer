#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

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

use strict;
use warnings;
use constant::defer;
use Test::More tests => 50;

BEGIN {
 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

my $want_version = 4;
is ($constant::defer::VERSION, $want_version, 'VERSION variable');
is (constant::defer->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { constant::defer->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { constant::defer->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# plain name

my $have_weaken;

{
  my $foo_runs = 0;
  use constant::defer FOO => sub { $foo_runs++; return 123 };

  my $orig_code;
  $orig_code = \&FOO;

  is (FOO, 123, 'FOO first run');
  is ($foo_runs, 1, 'FOO first runs code');

  is (&$orig_code(), 123, 'FOO orig second run');
  is ($foo_runs, 1, "FOO orig second doesn't run code");

  $have_weaken = eval { require Scalar::Util;
                        my $x = [ 'hello' ];
                        Scalar::Util::weaken($x);
                        if (defined $x) {
                          die "Oops, weakening didn't garbage collect";
                        }
                        1
                      };
  if (! $have_weaken) {
    diag "Scalar::Util::weaken() not available -- $@";
  }

 SKIP: {
    $have_weaken or skip "Scalar::Util::weaken() not available", 3;
    Scalar::Util::weaken ($orig_code);
    is ($orig_code, undef, 'orig FOO code garbage collected');

    $foo_runs = 0;
    is (FOO, 123, 'FOO second run');
    is ($foo_runs, 0, "FOO second doesn't run code");
  }
}

#------------------------------------------------------------------------------
# fully qualified name

{
  my $runs = 0;
  use constant::defer 'Some::Non::Package::Place::func' => sub {
    $runs = 1; return 'xyz' };

  is (Some::Non::Package::Place::func(), 'xyz',
      'explicit package first run');
  is ($runs, 1,
      'explicit package first run runs code');

  $runs = 0;
  is (Some::Non::Package::Place::func(), 'xyz',
      'explicit package second run');
  is ($runs, 0,
      'explicit package second run doesn\'t run code');
}

#------------------------------------------------------------------------------
# array value

{
  my $runs = 0;
  use constant::defer THREE => sub { $runs = 1;
                                     return ('a','b','c') };

  is_deeply ([ THREE() ], [ 'a', 'b', 'c' ],
             'THREE return values first run');
  is ($runs, 1,
      'THREE return values first run runs code');

  $runs = 0;
  is_deeply ([ THREE() ], [ 'a', 'b', 'c' ],
             'THREE return values second run');
  is ($runs, 0,
      'THREE return values second run doesn\'t run code');
}

{
  my $runs = 0;
  use constant::defer THREE_SCALAR => sub { $runs = 1;
                                            return ('a','b','c') };

  my $got = THREE_SCALAR();
  is ($got, 3,
      'three values in scalar context return values first run');
  is ($runs, 1,
      'three values in scalar context return values first run runs code');

  $runs = 0;
  $got = THREE_SCALAR();
  is ($got, 3,
      'three values in scalar context return values second run');
  is ($runs, 0,
      'three values in scalar context return values second run doesn\'t run code');
}

#------------------------------------------------------------------------------
# multiple names

{
  my $foo_runs = 0;
  use constant::defer
    PAIR_ONE => sub { 123 },
    PAIR_TWO => sub { 456 };
  is (PAIR_ONE, 123, 'PAIR_ONE');
  is (PAIR_TWO, 456, 'PAIR_TWO');
}
{
  my $foo_runs = 0;
  use constant::defer { HASH_ONE => sub { 123 },
                        HASH_TWO => sub { 456 } };
  is (HASH_ONE, 123, 'HASH_ONE');
  is (HASH_TWO, 456, 'HASH_TWO');
}
{
  my $foo_runs = 0;
  use constant::defer SHASH_ONE => sub { 123 },
                      { SHASH_TWO => sub { 456 },
                        SHASH_THREE => sub { 789 } };
  is (SHASH_ONE, 123, 'SHASH_ONE');
  is (SHASH_TWO, 456, 'SHASH_TWO');
  is (SHASH_THREE, 789, 'SHASH_THREE');
}

#------------------------------------------------------------------------------
# with can()

{
  my $runs = 0;
  package MyTestCan;
  use constant::defer CANNED => sub { $runs++; return 'foo' };

  package main;
  my $func = MyTestCan->can('CANNED');

  my $got = &$func();
  is ($got, 'foo', 'through can() - result');
  is ($runs, 1,    'through can() - run once');

  $got = &$func();
  is ($got, 'foo', 'through can() - 2nd result');
  is ($runs, 1,    'through can() - 2nd still run once');
}

#------------------------------------------------------------------------------
# with Exporter import()

{
  my $runs = 0;

  package MyTestImport;
  use vars qw(@ISA @EXPORT);
  use constant::defer TEST_IMPORT_FOO => sub { $runs++; return 'foo' };
  require Exporter;
  @ISA = ('Exporter');
  @EXPORT = ('TEST_IMPORT_FOO');

  package main;
  MyTestImport->import;

  my $got = TEST_IMPORT_FOO();
  is ($got, 'foo', 'through import - result');
  is ($runs, 1,    'through import - run once');

  $got = TEST_IMPORT_FOO();
  is ($got, 'foo', 'through import - 2nd result');
  is ($runs, 1,    'through import - 2nd still run once');
}

#------------------------------------------------------------------------------
# gc of supplied $subr after it's been called

{
  my $subr;
  BEGIN { $subr = sub { return 'gc me' } }
  use constant::defer WEAKEN_CONST => $subr;

  # including when the can() first func is retained
  my $cancode = main->can('WEAKEN_CONST');

  my @got = WEAKEN_CONST();
  is_deeply (\@got, ['gc me'], 'WEAKEN_CONST - result');

 SKIP: {
    $have_weaken or skip "Scalar::Util::weaken() not available", 1;

    Scalar::Util::weaken ($subr);
    is ($subr,   undef,   'WEAKEN_CONST - subr now undef');
  }
}

{
  my ($objref, $subr);
  my $runs = 0;
  BEGIN {
    my %obj = (foo => 'bar');
    $subr = sub { $runs++; return %obj };
    $objref = \%obj;
  }
  use constant::defer WEAKEN_OBJRET => $subr;

  # including when the can() first func is retained
  my $cancode = main->can('WEAKEN_OBJRET');

  my @got = WEAKEN_OBJRET();
  is_deeply (\@got, ['foo','bar'], 'WEAKEN_OBJRET - result');
  is ($runs, 1, 'WEAKEN_OBJRET - run once');

 SKIP: {
    $have_weaken or skip "Scalar::Util::weaken() not available", 2;
    Scalar::Util::weaken ($subr);
    Scalar::Util::weaken ($objref);
    is ($subr, undef,   'WEAKEN_OBJRET - subr now undef');
    is ($objref, undef, 'WEAKEN_OBJRET - objref now undef');
  }
}

#------------------------------------------------------------------------------
# gc of can() after called

{
  use constant::defer CAN_GC => sub { return 'gc me' };
  my $cancode = main->can('CAN_GC');

  my @got = CAN_GC();
  is_deeply (\@got, ['gc me'], 'CAN_GC - result');

 SKIP: {
    $have_weaken or skip "Scalar::Util::weaken() not available", 1;

    Scalar::Util::weaken ($cancode);
    is ($cancode, undef, 'CAN_GC - can() coderef now undef');
  }
}

#------------------------------------------------------------------------------
# gc of initial definition after called

{
  use constant::defer INITIAL_GC => sub { return 'gc me' };
  my $coderef = \&INITIAL_GC;

  my @got = INITIAL_GC();
  is_deeply (\@got, ['gc me'], 'INITIAL_GC - result');

 SKIP: {
    $have_weaken or skip "Scalar::Util::weaken() not available", 1;

    Scalar::Util::weaken ($coderef);
    is ($coderef, undef, 'INITIAL_GC - saved initial now undef');
  }
}

#------------------------------------------------------------------------------
# gc of runner helper after redefine

SKIP: {
  use constant::defer RUNNER_GC => sub { return 'gc me' };
  my $runner;
  BEGIN {
    $runner = $constant::defer::DEBUG_LAST_RUNNER;
    undef $constant::defer::DEBUG_LAST_RUNNER;
  }

  $runner or skip "DEBUG_LAST_RUNNER not enabled in defer.pm", 1;
  $have_weaken or skip "Scalar::Util::weaken() not available", 1;

  { no warnings 'redefine';
    *RUNNER_GC = sub () { 'new value' };
  }
  Scalar::Util::weaken ($runner);
  is ($runner, undef, 'RUNNER_GC - now undef');
  if ($runner) {
    require Devel::FindRef;
    diag Devel::FindRef::track($runner);
  }
}

exit 0;
