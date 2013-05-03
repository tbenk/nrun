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

package WorkerSsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;
use POSIX qw(getuid);

our @ISA = qw(NRun::Worker);

###
# module specification
our $MODINFO = {

  'MODE' => "ssh",
  'DESC' => "ssh based remote execution",
};

###
# create a new object.
#
# $_cfg - parameter hash where
# {
#   'ssh_args'   - arguments supplied to the ssh binary
#   'scp_args'   - arguments supplied to the scp binary
#   'ssh_binary' - ssh binary to be executed
#   'scp_binary' - scp binary to be executed
#   'ssh_user'   - ssh login user
#   'scp_user'   - scp login user
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_cfg = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{ssh_args}   = $_cfg->{ssh_args};
    $self->{scp_args}   = $_cfg->{scp_args};
    $self->{ssh_binary} = $_cfg->{ssh_binary};
    $self->{scp_binary} = $_cfg->{scp_binary};
    $self->{ssh_user}   = $_cfg->{ssh_user};
    $self->{scp_user}   = $_cfg->{scp_user};

    if (not defined($self->{ssh_user})) {

        ($self->{ssh_user}) = getpwuid(getuid());
    }

    if (not defined($self->{scp_user})) {

        ($self->{scp_user}) = getpwuid(getuid());
    }

    $self->{MODINFO} = $MODINFO;
    return $self;
}

###
# copy a file using ssh to $_host.
#
# $_host   - the host the command should be exeuted on
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- (
#      $ret - the return code 
#      $out - command output
#    )
sub copy {

    my $_self   = shift;
    my $_host   = shift;
    my $_source = shift;
    my $_target = shift;

    return _("$_self->{scp_binary} $_self->{scp_args} $_source $_self->{scp_user}\@$_host:$_target");
}

###
# execute the command using ssh on $_host.
#
# $_host    - the host the command should be exeuted on
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- (
#      $ret - the return code 
#      $out - command output
#    )
sub execute {

    my $_self    = shift;
    my $_host    = shift;
    my $_command = shift;
    my $_args    = shift;

    return _("$_self->{ssh_binary} $_self->{ssh_args} -l $_self->{ssh_user} $_host $_command $_args");
}

###
# delete a file using ssh on $_host.
#
# $_host - the host the command should be exeuted on
# $_file - the command that should be executed
# <- (
#      $ret - the return code 
#      $out - command output
#    )
sub delete {

    my $_self = shift;
    my $_host = shift;
    my $_file = shift;

    return _("$_self->{ssh_binary} $_self->{ssh_args} -l $_self->{ssh_user} $_host rm -f \"$_file\"");
}

1;

