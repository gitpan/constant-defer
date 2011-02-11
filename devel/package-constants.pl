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
use Package::Constants;
use Smart::Comments;

{
  package Foo;
  use constant PLAIN => 123;
  use constant::defer HELLO => sub { 123 };
  sub SUBR { 123 }
  sub SUBRPROT () { 123 }
  sub SUBRPRINT () { print "hello" }

  use constant::lexical LEX => 123;
  BEGIN {
    my @const = Package::Constants->list('Foo');
    ### @const
  }
}

my @const = Package::Constants->list('Foo');
### @const
