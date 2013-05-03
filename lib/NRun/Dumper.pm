#
# Copyright 2013 Timo Benk
# 
# This file is part of nrun.
# 
# nrun is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# nrun is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with nrun.  If not, see <http://www.gnu.org/licenses/>.
#
# Program: <FILE>
# Author:  <AUTHORNAME> <<AUTHOREMAIL>>
# Date:    <COMMITTERDATE>
# Ident:   <COMMITHASH>
# Branch:  <BRANCH>
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package NRun::Dumper;

use strict;
use warnings;

use NRun::Semaphore;

my $SEMAPHORE = NRun::Semaphore->new({key => int(rand(100000))});

###
# create a new object.
#
# $_obj - parameter hash where
# {
#   'dump' - one of ...
#            output             - dump the command output 
#            result             - dump the command result in csv format
#            output_no_hostname - dump the command output out omit the hostname
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{dump} = $_obj->{dump};

    return $self;
}

###
# dump the output
#
# $_host - the host this result belongs to
# $_ret  - the script return code
# $_out  - the script output
sub dump {

    my $_self = shift;
    my $_host = shift;
    my $_ret  = shift;
    my $_out  = shift;

    if ($_self->{dump} =~ /^output/) {

        if (not $_self->{dump} =~ /no_hostname$/) {

            $_out =~ s/^/$_host: /gms;
        }

        chomp($_out);
        $_out .= "\n"; # ensure newline at end of line

    } else {

        $_out =  "$_host; exit code $_ret\n";
    }

    $SEMAPHORE->lock();
    print $_out;
    $SEMAPHORE->unlock();
}

1;

