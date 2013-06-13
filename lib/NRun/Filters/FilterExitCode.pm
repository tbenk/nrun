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

###
# this filter will only print the exit codes.
package NRun::Filters::FilterExitCode;

use strict;
use warnings;

use File::Basename;
use NRun::Filter;

our @ISA = qw(NRun::Filter);

BEGIN {

    NRun::Filter::register ( {

        'FILTER' => "result",
        'DESC'   => "dump only the exit code",
        'NAME'   => "NRun::Filters::FilterExitCode",
    } );
}

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this filter module.
#
# $_cfg - parameter hash where
# {
#   'no_hostname' - if defined omit hostname prefix
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->SUPER::init($_cfg);

    $_self->{no_hostname} = $_cfg->{no_hostname};
}

###
# handle one line of data written on stdout.
#
# expected data format:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# $_data - the data to be handled
sub stdout {

    my $_self = shift;
    my $_data = shift;

    my @data = split(/;/, $_data);

    my ($message) = ($_data =~ m/[^"]"(.*)"[^"]*/);

    if ($data[5] eq "exit") {

        $_self->{data}->{$data[0]} = $message;
    } elsif ($data[5] eq "end") {

        my $message = delete($_self->{data}->{$data[0]});

        print STDOUT "$data[0]: $message\n" if (defined($message));
    }
}

###
# handle one line of data written on stderr.
#
# expected data format:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# $_data - the data to be handled
sub stderr {

    my $_self = shift;
    my $_data = shift;
}

1;

