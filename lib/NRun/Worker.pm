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

package NRun::Worker;

use strict;
use warnings;

use File::Basename;
use NRun::Semaphore;

my $semaphore;
my $workers = {};

###
# module specification
our $MODINFO = {

  'MODE' => "",
  'DESC' => "",
};

###
# return all available worker modules
sub workers {

    return $workers;
}

###
# dynamically load all available login modules
#
# $_cfg - option hash given to the submodules on creation
# $_sem - semaphore object 
sub init {

    my $_cfg = shift;
    my $_sem = shift;

    $semaphore = $_sem;

    my $basedir = dirname($INC{"NRun/Worker.pm"}) . "/Workers";

    opendir(DIR, $basedir) or die("$basedir: $!");
    while (my $module = readdir(DIR)) {

        if ($module =~ /\.pm$/i) {

            require "$basedir/$module";

            $module =~ s/\.pm$//i;

            my $object = $module->new($_cfg);
            $workers->{$object->mode()} = $object;
        }
    }
    close DIR;
}

###
# execute $_cmd. will die on SIGALRM.
#
# $_cmd -  the command to be executed
# <- (
#      $ret - the return code
#      $out - command output (joined stderr and stdout)
#    )
sub _ {

    my $_cmd = shift;

    my $pid = -128;
    my @out;

    local $SIG{USR1} = sub {

        $semaphore->lock();
        print STDERR "[$$]: ($pid) $_cmd\n";
        print STDERR "[$$]: " . join("[$$]: ", @out) if (scalar(@out));
        $semaphore->unlock();
    };

    local $SIG{USR2} = sub {

        $semaphore->lock();

        if (not open(LOG, ">>trace.txt")) {

            print STDERR "trace.txt: $!\n";
            return;
        }

        print LOG "[$$]: ($pid) $_cmd\n";
        print LOG "[$$]: " . join("[$$]: ", @out) if (scalar(@out));

        close(LOG);

        $semaphore->unlock();
    };

    local $SIG{INT} = sub {

        kill(9, $pid);
        push(@out, "SIGINT received\n");
        die join("", @out);
    };

    local $SIG{ALRM} = sub {

        kill(9, $pid);
        push(@out, "SIGALRM received (timeout)\n");
        die join("", @out);
    };

    local $SIG{TERM} = sub {

        kill(9, $pid);
        push(@out, "SIGTERM received\n");
        die join("", @out);
    };

    $pid = open(CMD, "$_cmd 2>&1 2>&1|") or die "$_cmd: $!\n"; 
    while (my $line = <CMD>) {
    
       push(@out, $line);
    }
    close(CMD);

    return ($? >> 8, join("", @out));
}

###
# return this modules mode
sub mode {

    my $_self = shift;
    return $_self->{MODINFO}->{MODE};
}

###
# return this modules description
sub desc {

    my $_self = shift;
    return $_self->{MODINFO}->{DESC};
}

1;

