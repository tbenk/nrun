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
# Branch:  <REFNAMES>
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

###
# this is the base module for all "Filter" implementations and
# is responsible for loading the available implementations
# at runtime.
#
# a filter formats the ouput from the child processes
package NRun::Filter;

use strict;
use warnings;

use File::Basename;

###
# automagically load all available modules
INIT {

    my $basedir = dirname($INC{"NRun/Filter.pm"}) . "/Filters";

    opendir(DIR, $basedir) or die("$basedir: $!");
    while (my $module = readdir(DIR)) {

        if ($module =~ /\.pm$/i) {

            require "$basedir/$module";
        }
    }
    close DIR;
}

###
# all available filters will be registered here
my $filters = {};

###
# will be called by the check modules on INIT.
#
# $_cfg - parameter hash where
# {
#   'FILTER' - filter name
#   'DESC'   - filter description
#   'NAME'   - module name
# }
sub register {

    my $_cfg = shift;

    $filters->{$_cfg->{FILTER}} = $_cfg;
}

###
# return all available filter modules
sub filters {

    return $filters;
}

###
# initialize this filter module.
sub init {

    my $_self = shift;
}

1;
