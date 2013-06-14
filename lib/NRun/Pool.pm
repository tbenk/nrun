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
# this module is responsible for the creation of the process pool.
#
# each dispatched process will be connected to the sink object which
# is responsible for passing the output from the worker modules to the
# filter/logger modules.
##

package NRun::Pool;

use strict;
use warnings;

###
# create a new pool object.
#
# $_obj - parameter hash where
# {
#   'timeout'  => timeout in seconds
#   'objects'  => the target objects
#   'nmax'     => maximum number of parallel login processes
#   'callback' => callback function to be executed in parallel
#                 signature: sub callback ($object)
#   'sink'     => the sink object
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{timeout} = $_obj->{timeout};
    $self->{nmax}    = $_obj->{nmax};
    $self->{objects} = $_obj->{objects};
    $self->{sink}    = $_obj->{sink};

    $self->{callback} = $_obj->{callback};

    $self->init();

    return $self;
}

###
# deliver signal to all child processes
sub handler_int {

    my $_pids = shift;

    kill(INT => @$_pids);
}

###
# deliver signal to all child processes
sub handler_term {

    my $_pids = shift;

    kill(TERM => @$_pids);
}

###
# dispatch the worker processes.
sub init {

    my $_self = shift;

    my @pids;

    my $handler_int  = NRun::Signal::register('INT',  \&handler_int,  [ \@pids ], $$);
    my $handler_term = NRun::Signal::register('TERM', \&handler_term, [ \@pids ], $$);
    
    foreach my $bunch (NRun::Util::bunches($_self->{objects}, $_self->{nmax})) {
 
        $_self->{sink}->pipe();

        my $pid = fork();
        if (not defined $pid) {

            die("error: unable to fork");
        } elsif ($pid == 0) {

            $_self->{sink}->connect();
            foreach my $object (@$bunch) {

                alarm($_self->{timeout});

                $_self->{callback}->($object);
            };
            $_self->{sink}->disconnect();

            exit(0);
        } else {

            push (@pids, $pid);
        }
    }
}

1;
