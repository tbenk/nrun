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
#   'dumper'     - dumper object
#   'logger'     - logger object
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
# do some general checks.
#
# - ping check will be checked if $_self->{skip_ns_check}
# - dns check will be checked if $_self->{skip_dns_check}
#
# <- 1 on success and 0 on error
sub pre_check {

    my $_self = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_check};

    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    my ( $out, $ret ) = $_self->do($cmdline);
    return 1 if ($ret != 0);

    return $_self->SUPER::pre_check();
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

    my ( $out, $ret ) = $_self->do($cmdline);
    return $ret;
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

    my ( $out, $ret ) = $_self->do($cmdline);
    return $ret;
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

    my ( $out, $ret ) = $_self->do($cmdline);
    return $ret;
}

###
# execute $_cmd. will die on SIGALRM, SIGINT or SIGTERM.
#
# additionally to Worker::do() do() will scan command output
# for nsh error messages.
#
# bladelogic seems to have a problem when doing too many parallel
# requests at once. If this is the case and the action fails for that
# reason, -128 is returned.
#
# $_cmd -  the command to be executed
# <- (
#      $out - command output
#      $ret - the return code (-128 indicates too many parallel connections)
#    )
sub do {

    my $_self = shift;
    my $_cmd  = shift;

    my ( $out, $ret ) = $_self->SUPER::do($_cmd);

    # return -128 on messages indicating too many parallel connections
    if (   grep(/SSO Error: Error reading server greeting/,            $out)
        or grep(/SSO Error: Could not load credential cache file/,     $out)
        or grep(/SSL_connect/,                                         $out)
        or grep(/nexec: Error accessing host .* Connection timed out/, $out)
        or grep(/Unable to reach .* Connection timed out/,             $out))
    {

        $_self->{dumper}->code($NRun::Constants::RSCD_ERROR);
        $_self->{logger}->code($NRun::Constants::RSCD_ERROR);

        return ( $out, $NRun::Constants::RSCD_ERROR );
    }

    return ( $out, $ret );
}

1;

