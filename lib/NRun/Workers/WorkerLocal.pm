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

package NRun::Worker::WorkerLocal;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;

our @ISA = qw(NRun::Worker);

BEGIN {

    NRun::Worker::register ( {

        'MODE' => "local",
        'DESC' => "execute the script locally, set TARGET_HOST on each execution",
        'NAME' => "NRun::Worker::WorkerLocal",
    } );
}

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this worker module.
#
# $_cfg - parameter hash where
# {
#   'hostname'   - hostname this worker should act on
#   'dumper'     - dumper object
#   'logger'     - logger object
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->SUPER::init($_cfg);
}

###
# copy a file to $_self->{hostname}.
#
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- the return code
sub copy {

    my $_self   = shift;
    my $_source = shift;
    my $_target = shift;

    $_self->{logger}->push("not implemented");
    $_self->{dumper}->push("not implemented");
    $_self->{logger}->code(1);
    $_self->{dumper}->code(1);

    return 1;
}

###
# execute the command locally and set environment variable TARGET_HOST
# to $_self->{hostname}.
#
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- the return code
sub execute {

    my $_self    = shift;
    my $_command = shift;
    my $_args    = shift;

    my ( $out, $ret ) = $_self->do("TARGET_HOST=$_self->{hostname} $_command $_args");
    return $ret;
}

###
# delete a file on $_self->{hostname}.
#
# $_file - the command that should be executed
# <- the return code
sub delete {

    my $_self = shift;
    my $_file = shift;

    $_self->{logger}->push("not implemented");
    $_self->{dumper}->push("not implemented");
    $_self->{logger}->code(1);
    $_self->{dumper}->code(1);

    return 1;
}

1;

