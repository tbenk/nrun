#!/usr/bin/perl
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

package NRun::Util;

use strict;
use warnings;

use POSIX qw(getuid);

###
# remove all duplicate entries from array
#
# my @_arr - the array the duplicates should be removed from
# <- the array with all duplicates removed from
sub uniq {

    my @_arr = @_;

    return keys %{ { map { $_ => 1 } @_arr } } ;
}

###
# resolve a target definition.
#
# a target definition may be an alias defined in the
# configuration file, a file name containing the target
# hosts or simply the hostname.
#
# $_tgt   - the target to be resolved
# $_alias - the alias definitions
# $_seen  - hash ref with a key for every target already seen
# <- the resolved target hostnames
sub resolve_target {

    my $_tgt   = shift;
    my $_alias = shift;
    my $_seen  = shift;

    $_seen = {} if not defined($_seen);
    if (defined($_seen->{$_tgt})) {

        return;
    }
    $_seen->{$_tgt} = 1;

    my @targets;

    if (defined($_alias) and defined($_alias->{$_tgt})) {

        foreach my $tgt (@{$_alias->{$_tgt}}) {

            @targets = ( @targets, resolve_target($tgt, $_alias, $_seen) );
        }
    } elsif (-e $_tgt) {

        foreach my $tgt (read_hosts($_tgt)) {

            @targets = ( @targets, resolve_target($tgt, $_alias, $_seen) );
        }
    } else {

        @targets = ( $_tgt );
    }

    return @targets;
}

###
# return users home directory
#
# <- the current users home directory
sub home {

    my $home = (getpwuid(getuid()))[7];
}

###
# read the hosts file.
#
# $_file - the file containing the hostnames, one per line
# <- an array containing all hostnames
sub read_hosts {

    my $_file = shift;

    my $hosts = {};

    open(HOSTS, "<$_file") or die("Cannot open $_file: $!");
    foreach my $host (<HOSTS>) {

        chomp($host);
        $host =~ s/^\s+//;
        $host =~ s/\s+$//;

        if (not $host =~ /^ *$/) {

            # filter out duplicate entries
            $hosts->{$host} = 1;
        }
    }

    return keys(%$hosts);
}

1;
