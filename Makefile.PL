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
use ExtUtils::MakeMaker;
use lib 'inc';
use MyMakeMakerExtras;

MyMakeMakerExtras::WriteMakefile
  (NAME         => 'constant::defer',
   ABSTRACT     => 'Constant subs with deferred value calculation.',
   VERSION_FROM => 'lib/constant/defer.pm',
   PREREQ_PM    => {
                    'Test::More' => 0,
                    'warnings' => 0,
                    'vars' => 0,
                   },
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl',
   SIGN         => 1,

   META_MERGE
   => { no_index => { directory => [ 'devel' ] },
        resources
        => { homepage
             => 'http://user42.tuxfamily.org/constant-defer/index.html',
           },
        optional_features
        => { maximum_tests
             => { description => 'Have "make test" do as much as possible.',
                  requires => { 'Scalar::Util'     => 0,
                                'Test::NoWarnings' => 0,
                              },
                },
             maximum_devel
             => { description => 'Stuff used variously for development.',
                  requires => { 'base'         => 0,
                                'Data::Dumper' => 0,
                                'File::Spec'   => 0,
                                'lib::abs'     => 0,
                                'Scalar::Util' => 0,
                                'warnings'     => 0,
                              },
                },
           },
      },
  );
