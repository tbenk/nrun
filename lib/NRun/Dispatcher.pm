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

package NRun::Dispatcher;

use strict;
use warnings;

use POSIX qw(:sys_wait_h);
use Time::HiRes qw(usleep);

###
# create a new object.
#
# $_obj - parameter hash where
# {
#   'timeout' => timeout in seconds
#   'objects' => the target objects
#   'nmax'    => maximum number of parallel login processes

#   'callback_action' => callback function to be executed in parallel
#                        signature: my ($ret, $out) = sub callback_action ($object)
#   'callback_result' => callback function to be executed to handle the 
#                        return values of callback_action (optional)
#                        signature: sub callback_result ($object, $ret, $out)
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

    $self->{callback_action} = $_obj->{callback_action};
    $self->{callback_result} = $_obj->{callback_result};

    return $self;
}

###
# dispatch next process. will generate a SIGALRM after $_self->{timeout} 
# seconds. this signal must be handled inside callback_action(). 
#
# example:
#
# local $SIG{ALRM} = sub {
#
#     die "SIGALRM received (timeout)\n";
# };
#
# $_pool    - the current child process pool
# $_pids    - map to store pid->object relation
# $_object  - the object to be executed against
sub dispatch {

    my $_self   = shift;
    my $_pool   = shift;
    my $_pids   = shift;
    my $_object = shift;

    my $pid = fork();
    if (not defined $pid) {

        die("error: unable to fork");
    } elsif ($pid == 0) {


        alarm($_self->{timeout});

        my ($ret, $out);
        eval {

            ($ret, $out) = $_self->{callback_action}->($_object);
        };
        if (defined($_self->{callback_result})) {

        }
        if ($@) {

            $_self->{callback_result}->($_object, -255, $@);
        } else {

            $_self->{callback_result}->($_object, $ret, $out);
        }

        exit(0);
    } else {

        $_pids->{$pid} = $_object;
        push(@$_pool, $pid);
    }
}

###
# process dispatching handler.
sub run {

    my $_self = shift;

    my (@pool, %pids);

    # rampup
    while (scalar(@pool) < $_self->{nmax} and scalar(@{$_self->{objects}}) > 0) {

        $_self->dispatch(\@pool, \%pids, pop(@{$_self->{objects}}));

        usleep(100000);
    }

    # hold level
    while (scalar(@{$_self->{objects}}) > 0) {

        my $pid = pop(@pool);

        my $ret = waitpid($pid, WNOHANG);
        if ($ret == $pid) {

            if ($? != 0 and defined($_self->{callback_result})) {

                $_self->{callback_result}->($pids{$pid}, $?, "child process exited unexpectedly");
            }

            $_self->dispatch(\@pool, \%pids, pop(@{$_self->{objects}}));
        } else {

            unshift(@pool, $pid);
        }

        usleep(100000);
    }

    # tear down
    while (scalar(@pool) > 0) {

        my $pid = pop(@pool);

        my $ret = waitpid($pid, WNOHANG);
        if ($ret == $pid) {

            if ($? != 0 and defined($_self->{callback_result})) {

                $_self->{callback_result}->($pids{$pid}, $?, "child process exited unexpectedly");
            }
        } else {

            unshift(@pool, $pid);
        }

        usleep(100000);
    }
}

1;

