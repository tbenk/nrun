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
# this worker implements nsh based remote execution
package NRun::Worker::WorkerNsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;
use NRun::Constants;

our @ISA = qw(NRun::Worker);

BEGIN {

    NRun::Worker::register ( {

        'MODE' => "nsh",
        'DESC' => "nsh based remote execution",
        'NAME' => "NRun::Worker::WorkerNsh",
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
#   'nsh_copy'   - commandline for the copy command (SOURCE, TARGET, HOSTNAME will be replaced)
#   'nsh_exec'   - commandline for the exec command (COMMAND, ARGUMENTS, HOSTNAME will be replaced)
#   'nsh_delete' - commandline for the delete command (FILE, HOSTNAME will be replaced)
#   'nsh_check'  - commandline for the agentinfo check command (HOSTNAME will be replaced)
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->SUPER::init($_cfg);

    $_self->{nsh_copy}   = $_cfg->{nsh_copy};
    $_self->{nsh_exec}   = $_cfg->{nsh_exec};
    $_self->{nsh_delete} = $_cfg->{nsh_delete};
    $_self->{nsh_check}  = $_cfg->{nsh_check};
}

###
# copy a file using nsh to $_self->{hostname}.
#
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- the return code (-128 indicates too many parallel connections)
sub copy {

    my $_self   = shift;
    my $_source = shift;
    my $_target = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_copy};

    $cmdline =~ s/SOURCE/$_source/g;
    $cmdline =~ s/TARGET/$_target/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

###
# execute the command using nsh on $_self->{hostname}.
#
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- the return code (-128 indicates too many parallel connections)
sub execute {

    my $_self    = shift;
    my $_command = shift;
    my $_args    = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_copy};

    $cmdline =~ s/COMMAND/$_command/g;
    $cmdline =~ s/ARGUMENTS/$_args/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

###
# delete a file using nsh on $_self->{hostname}.
#
# $_file - the file that should be deleted
# <- the return code (-128 indicates too many parallel connections)
sub delete {

    my $_self = shift;
    my $_file = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_copy};

    $cmdline =~ s/FILE/$_file/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

1;

