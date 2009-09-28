#!/usr/bin/perl

# Copyright 2009 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# constant-defer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.


# Usage: ./instance.pl
#
# This is roughly how to press constant::defer into service for a once-only
# object instance creation.
#
# The creation code here is entirely within the instance() routine so after
# it's run it's discarded, which may save a few bytes of memory.  If you
# wanted other object instances as well as a shared one then you'd split out
# a usual sort of new().
#
# The $class parameter can help subclassing.  A call like
#
#     MyClass::SubClass->instance
#
# blesses into that subclass.  But effectively there's only one instance
# behind the two MyClass and MyClass::SubClass and whichever runs first is
# the class created.  If you only ever want one of the two then that can be
# fine, otherwise it might be very bad.
#
# There's no reason not to take other arguments in the instance() creation,
# except that they only have an effect on the first call, so it may be more
# confusing than flexible.
#
# Generally you're best off using Class::Singleton (or
# Class::Singleton::Weak) but if you've got constant::defer for other things
# then this is compact and cute.
#

package MyClass;
use strict;
use warnings;

use constant::defer instance => sub {
  my ($class) = @_;
  return bless { foo => 123 }, $class;
};
sub do_something {
  print "do something ...\n";
}

package main;
printf "instance %s\n", MyClass->instance;
printf "instance %s\n", MyClass->instance;

my $obj = MyClass->instance;
$obj->do_something;

exit 0;
