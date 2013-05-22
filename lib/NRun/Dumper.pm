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

package NRun::Dumper;

use strict;
use warnings;

use NRun::Semaphore;
use NRun::Signal;
use NRun::Constants;

###
# create a new object.
#
# $_cfg - parameter hash where
# {
#   'hostname'  - the hostname this dumper is responsible for
#   'semaphore' - the semaphore lock object
#   'mode'      - one of ...
#                 output_sync_hostname     - dump the command output incl hostname (synchronized)
#                 output_sync_no_hostname  - dump the command output excl hostname (synchronized)
#                 output_async_hostname    - dump the command output incl hostname (not synchronized)
#                 output_async_no_hostname - dump the command output excl hostname (not synchronized)
#                 result_no_hostname       - dump the command result in csv format excl hostname
#                 result_hostname          - dump the command result in csv format incl hostname
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_cfg = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{mode}          = $_cfg->{mode}; 
    $self->{hostname}      = $_cfg->{hostname};
    $self->{semaphore}     = $_cfg->{semaphore};
    $self->{semaphore_key} = $_cfg->{semaphore}->key();

    $self->{buffer} = [];
    $self->{code}   = 0;

    $self->{handler_usr1} = NRun::Signal::register('USR1', \&handler_usr1, [ \$self ]);
    $self->{handler_term} = NRun::Signal::register('TERM', \&handler_term, [ \$self ]);
    $self->{handler_int}  = NRun::Signal::register('INT',  \&handler_int,  [ \$self ]);
    $self->{handler_alrm} = NRun::Signal::register('ALRM', \&handler_alrm, [ \$self ]);

    return $self;
}

###
# SIGTERM signal handler
sub handler_term {

    my $_self = shift;

    $$_self->push("SIGTERM received\n");
    $$_self->code($NRun::Constants::CODE_SIGTERM);

    $$_self->destroy();
}

###
# SIGINT signal handler
sub handler_int {

    my $_self = shift;

    $$_self->push("SIGINT received\n");
    $$_self->code($NRun::Constants::CODE_SIGINT);

    $$_self->destroy();
}

###
# SIGALRM signal handler
sub handler_alrm {

    my $_self = shift;

    $$_self->push("SIGALRM received\n");
    $$_self->code($NRun::Constants::CODE_SIGALRM); 

    $$_self->destroy();
}

###
# SIGUSR1 signal handler
sub handler_usr1 {

    my $_self = shift;

    return if (defined($$_self->{closed}));

    $$_self->{semaphore}->unlock();
    $$_self->{semaphore}->lock();

    if (defined($$_self->{command})) {

        print "$$_self->{hostname}\[$$\]: $$_self->{command}\n";
    }

    if (scalar(@{$$_self->{buffer}})) {
  
        print "$$_self->{hostname}\[$$\]: " . join("$$_self->{hostname}\[$$\]: ", @{$$_self->{buffer}});
    }

    print "$$_self->{hostname}\[$$\]: SIGUSR1 received\n";

    $$_self->{semaphore}->unlock();
}

###
# push a message into the buffer.
#
# $_msg - the message to be pushed
sub push {

    my $_self = shift;
    my $_msg  = shift;

    return if (defined($_self->{closed}));

    if ($_self->{mode} =~ /^output_async/) {

        $_self->{semaphore}->lock();
        if ($_self->{mode} =~ /no_hostname$/) {

            print $_msg;
        } else {

            print "$_self->{hostname}: $_msg";
        }
        $_self->{semaphore}->unlock();
    } else {

        push(@{$_self->{buffer}}, $_msg);
    }
}

###
# set the return code value.
#
# $_code - the code to be set
sub code {

    my $_self = shift;
    my $_code = shift;

    return if (defined($_self->{closed}));

    $_self->{code} = $_code;
}

###
# set the currently running command.
#
# $_command - the command to be set
sub command {

    my $_self = shift;
    my $_command = shift;

    return if (defined($_self->{closed}));

    $_self->{command} = $_command;
}

###
# global destruction in DESTROY may set $_self->{semaphore} to undef.
sub destroy {

    my $_self = shift;

    return if (defined($_self->{closed}));

    $_self->{closed} = 1;

    NRun::Signal::deregister('USR1', $_self->{handler_usr1});
    NRun::Signal::deregister('TERM', $_self->{handler_term});
    NRun::Signal::deregister('INT',  $_self->{handler_int});
    NRun::Signal::deregister('ALRM', $_self->{handler_alrm});

    $_self->{semaphore}->lock();

    if ($_self->{mode}  =~ /^result/) {

        if ($_self->{mode} =~ /no_hostname$/) {

            print "exit code $_self->{code}\n";
        } else {

            print "$_self->{hostname}; exit code $_self->{code}\n";
        }
    } elsif (scalar(@{$_self->{buffer}})) {
  
        if ($_self->{mode} =~ /no_hostname$/) {

            print join("", @{$_self->{buffer}});
        } else {

            print "$_self->{hostname}: " . join("$_self->{hostname}: ", @{$_self->{buffer}});
        }
    }

    $_self->{semaphore}->unlock();
}

1;

