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

package NRun::Semaphore;

use strict;
use warnings;

use IPC::Semaphore;
use IPC::SysV qw(IPC_CREAT);
use Time::HiRes qw(usleep);

###
# create a new object.
#
# $_obj - parameter hash where
# {
#   'key' => semaphore key or undef if a new unique semaphore should be created
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    if (not defined($_obj) or not defined($_obj->{key})) {

        $self->{key} = int(rand(100000));
        while (new IPC::Semaphore($self->{key}, 1, 0)) {

            $self->{key} = int(rand(100000));
        }

        $self->{semaphore} = new IPC::Semaphore($self->{key}, 1, 0600 | IPC_CREAT);
        $self->{semaphore}->op(0,1,0);
    } else {

        $self->{key} = $_obj->{key};
        $self->{semaphore} = new IPC::Semaphore($self->{key}, 1, 0);
    }

    return $self;
}

###
# set a global lock. will block until the global lock could be set.
#
# <- returns 0 on failure and 1 on success
sub lock {

    my $_self = shift;

    return $_self->{semaphore}->op(0,-1,0);
}

###
# return the semaphore key of this instance.
#
# <- the semaphore key of this instance
sub key {

    my $_self = shift;
  
    return $_self->{key};
}

###
# unset a global lock.
#
# <- returns 0 on failure and 1 on success
sub unlock {

    my $_self = shift;

    return  $_self->{semaphore}->op(0,1,0);
}

###
# remove the semaphore.
sub delete {

    my $_self = shift;

    if (defined($_self->{semaphore})) {

        $_self->{semaphore}->remove();
    }
}

1;

