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

###
# this package provides some utility functions.
###

package NRun::Util;

use strict;
use warnings;

use YAML qw(LoadFile);
use POSIX qw(getuid);

###
# remove all duplicate entries from array.
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

            push(@targets, resolve_target($tgt, $_alias, $_seen));
        }
    } elsif (-e $_tgt) {

        foreach my $tgt (read_hosts($_tgt)) {

            push(@targets, resolve_target($tgt, $_alias, $_seen));
        }
    } else {

        push(@targets, $_tgt);
    }

    return @targets;
}

###
# return the users home directory.
#
# <- the current users home directory
sub home {

    my $home = (getpwuid(getuid()))[7];
}

###
# read a file containing hostnames.
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

            $hosts->{$host} = 1;
        }
    }

    return keys(%$hosts);
}

##
# read the configuration files.
#
# $_files - the files to be read (values in last file will overwrite values in first file)
sub read_config_files {

    my $_files = shift;

    my $config = {};

    foreach my $file (@$_files) {
  
        if (-e $file) {
  
            my $options = { %{LoadFile($file)} };
            my $aliases = merge($config->{alias}, $options->{alias});

            my $args_nrun  = merge($config->{nrun}, $options->{nrun});
            my $args_ncopy = merge($config->{ncopy}, $options->{ncopy});

            $config = merge($config, $options);

            $config->{alias} = $aliases; 
            $config->{nrun}  = $args_nrun; 
            $config->{ncopy} = $args_ncopy; 
        }
    }

    return $config;
}

###
# merge two hashes, values from $_h2 will overwrite values from $_h1.
#
# $_h1 - hash reference 1 to be merged
# $_h2 - hash reference 2 to be merged
sub merge {

    my $_h1 = shift;
    my $_h2 = shift;

    if (not defined($_h1)) {

        return $_h2;
    } elsif (not defined($_h2)) {

        return $_h2;
    } 

    return { %$_h1, %$_h2 };
}

###
# take all entries from @$_objects and distribute each entry evenly into
# $_num new arrays.
#
# $_objects - the array to be splitted
# $_num     - the number of arrays to be returned
# <- a list of array references
sub bunches {

    my $_objects = shift;
    my $_num     = shift;

    my @bunches;
    foreach my $idx (0..($_num-1)) {

        $bunches[$idx] = [];
    }

    for (my $idx = 0; $idx < scalar(@{$_objects}); $idx++) {

        push(@{$bunches[$idx % $_num]}, $_objects->[$idx]);
    }

    return @bunches;
}

1;
