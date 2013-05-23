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

package NRun::Worker::WorkerSsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;
use POSIX qw(getuid);

our @ISA = qw(NRun::Worker);

BEGIN {

    NRun::Worker::register ( {

        'MODE' => "ssh",
        'DESC' => "ssh based remote execution",
        'NAME' => "NRun::Worker::WorkerSsh",
    } );
}

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;
    my $_cfg = shift;

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
#   'ssh_args'   - arguments supplied to the ssh binary
#   'scp_args'   - arguments supplied to the scp binary
#   'ssh_binary' - ssh binary to be executed
#   'scp_binary' - scp binary to be executed
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->SUPER::init($_cfg);

    $_self->{ssh_args}   = $_cfg->{ssh_args};
    $_self->{scp_args}   = $_cfg->{scp_args};
    $_self->{ssh_binary} = $_cfg->{ssh_binary};
    $_self->{scp_binary} = $_cfg->{scp_binary};
}

###
# copy a file using ssh to $_self->{hostname}.
#
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- the return code
sub copy {

    my $_self   = shift;
    my $_source = shift;
    my $_target = shift;

    my ( $out, $ret ) = $_self->do("$_self->{scp_binary} $_self->{scp_args} $_source $_self->{hostname}:$_target");
    return $ret;
}

###
# execute the command using ssh on $_self->{hostname}.
#
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- the return code
sub execute {

    my $_self    = shift;
    my $_command = shift;
    my $_args    = shift;

    my ( $out, $ret ) = $_self->do("$_self->{ssh_binary} $_self->{ssh_args} $_self->{hostname} $_command $_args");
    return $ret;
}

###
# delete a file using ssh on $_self->{hostname}.
#
# $_file - the file that should be deleted
# <- the return code
sub delete {

    my $_self = shift;
    my $_file = shift;

    my ( $out, $ret ) = $_self->do("$_self->{ssh_binary} $_self->{ssh_args} $_self->{hostname} rm -f \"$_file\"");
    return $ret;
}

1;

