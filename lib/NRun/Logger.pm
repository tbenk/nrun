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

package NRun::Logger;

use strict;
use warnings;

use File::Path;
use Date::Format;
use NRun::Semaphore;
use NRun::Signal;

###
# create a new object.
#
# $_cfg - parameter hash where
# {
#   'hostname'  - the hostname this dumper is responsible for
#   'semaphore' - the semaphore lock object
#   'basedir'   - the basedir the logfiles hsould be written to
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_cfg = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{basedir}       = $_cfg->{basedir};
    $self->{hostname}      = $_cfg->{hostname};
    $self->{semaphore}     = $_cfg->{semaphore};

    $self->{buffer} = [];
    $self->{code}   = 0;

    mkpath("$self->{basedir}/hosts");

    $self->{handler_term} = NRun::Signal::register('USR2', \&handler_usr2, [ \$self ]);
    $self->{handler_term} = NRun::Signal::register('TERM', \&handler_term, [ \$self ]);
    $self->{handler_int}  = NRun::Signal::register('INT',  \&handler_int,  [ \$self ]);
    $self->{handler_alrm} = NRun::Signal::register('ALRM', \&handler_alrm, [ \$self ]);

    unlink("$self->{basedir}/../latest");
    symlink("$self->{basedir}", "$self->{basedir}/../latest");

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
# SIGUSR2 signal handler
sub handler_usr2 {

    my $_self = shift;

    return if (defined($$_self->{closed}));

    $$_self->{semaphore}->unlock();
    $$_self->{semaphore}->lock();

    my $date = time2str("%Y%m%d_%H_%M_%S", time);
    if (not open(TRC, ">>$$_self->{basedir}/trace_$date.log")) {

        print "error: $$_self->{basedir}/trace.log: $!\n";

        $$_self->{semaphore}->unlock();
        return;
    }

    if (defined($$_self->{command})) {

        print TRC "$$_self->{hostname}\[$$\]: $$_self->{command}\n";
    }

    if (scalar(@{$$_self->{buffer}})) {
  
        print TRC "$$_self->{hostname}\[$$\]: " . join("$$_self->{hostname}\[$$\]: ", @{$$_self->{buffer}});
    }

    print TRC "$$_self->{hostname}\[$$\]: SIGUSR1 received\n";

    close(TRC);

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

    push(@{$_self->{buffer}}, $_msg);
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

    NRun::Signal::deregister('USR2', $_self->{handler_usr2});
    NRun::Signal::deregister('TERM', $_self->{handler_term});
    NRun::Signal::deregister('INT',  $_self->{handler_int});
    NRun::Signal::deregister('ALRM', $_self->{handler_alrm});

    $_self->{semaphore}->lock();

    open(RES, ">>$_self->{basedir}/results.log")                  or die("$_self->{basedir}/results.log: $!");
    open(LOG, ">>$_self->{basedir}/hosts/$_self->{hostname}.log") or die("$_self->{basedir}/$_self->{hostname}.log: $!");
    open(OUT, ">>$_self->{basedir}/output.log")                   or die("$_self->{basedir}/output.log: $!");

    print RES "$_self->{hostname}; exit code $_self->{code}; $_self->{basedir}/hosts/$_self->{hostname}.log\n";

    if (scalar(@{$_self->{buffer}})) {
  
        print LOG join("", @{$_self->{buffer}});
        print OUT $_self->{hostname} . ": " . join($_self->{hostname} . ": ", @{$_self->{buffer}});
    }


    close(OUT);
    close(RES);
    close(LOG);

    $_self->{semaphore}->unlock();
}

1;

