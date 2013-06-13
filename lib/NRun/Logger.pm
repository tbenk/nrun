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
# this is the base module for all "Logger" implementations and
# is responsible for loading the available implementations
# at runtime.
#
# a logger formats the ouput from the child processes and writes
# this output into a logfile.
package NRun::Logger;

use strict;
use warnings;

use File::Basename;

###
# automagically load all available modules
INIT {

    my $basedir = dirname($INC{"NRun/Logger.pm"}) . "/Loggers";

    opendir(DIR, $basedir) or die("$basedir: $!");
    while (my $module = readdir(DIR)) {

        if ($module =~ /\.pm$/i) {

            require "$basedir/$module";
        }
    }
    close DIR;
}

###
# all available logger will be registered here
my $loggers = {};

###
# will be called by the check modules on INIT.
#
# $_cfg - parameter hash where
# {
#   'LOGGER' - logger name
#   'DESC'   - logger description
#   'NAME'   - module name
# }
sub register {

    my $_cfg = shift;

    $loggers->{$_cfg->{LOGGER}} = $_cfg;
}

###
# return all available logger modules
sub loggers {

    return $loggers;
}

###
# initialize this logger module.
sub init {

    my $_self = shift;
}

1;

