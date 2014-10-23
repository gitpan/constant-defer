# Copyright 2009, 2010 Kevin Ryde

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

package MyConstantDeferExport;
use base 'Exporter';
our @EXPORT_OK = ('my_ctime');

use constant::defer my_ctime => sub { print "my_ctime runs\n";
                                      require POSIX;
                                      return POSIX::ctime(time());
                                    };
1;
__END__
