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
# this check checks whether the provided hostname is resolveable.
###

package NRun::Checks::CheckNs;

use strict;
use warnings;

use File::Basename;
use NRun::Check;

our @ISA = qw(NRun::Check);

BEGIN {

    NRun::Check::register ( {

        'CHECK' => "ns",
        'DESC'  => "check if hostname is resolvable",
        'NAME'  => __PACKAGE__,
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
# initialize this check module.
#
# $_cfg - parameter hash where
# {
#   'hostname' - hostname this check should act on
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{hostname} = $_cfg->{hostname};
}

###
# execute the check on $_self->{hostname}.
#
# on error, the following string will be printed on stderr:
#
# HOSTNAME;stderr;PID;n/a;error;"OUTPUT"
#
# <- 1 on success and 0 on error
sub execute {

    my $_self = shift;

    if (not gethostbyname($_self->{hostname})) {
    
        print STDOUT "$_self->{hostname};stderr;" . time() . ";$$;n/a;error;\"dns entry is missing for $_self->{hostname}\"\n";
        print STDERR "$_self->{hostname};stdout;" . time() . ";$$;n/a;exit;\"exit code $NRun::Constants::CHECK_FAILED_NS\"\n";

        return 0;
    }

    return 1;
}

1;
