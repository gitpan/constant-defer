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


use strict;
use warnings;

use constant::defer FOO => sub {
  print "now calculating FOO ...\n";
  print "  ... done\n";
  return 12345;
};

printf "FOO is %d\n", FOO;
printf "FOO is %d\n", FOO;

exit 0;
