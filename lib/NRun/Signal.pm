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

package NRun::Signal;

###
# all handlers will be registered here
my $HANDLERS = {};

###
# local signal handlers.
#
# calls all registered handlers in $HANDLERS.
#
# $_signal - the signal that triggered this call
sub _handler {

    my $_signal = shift;

    foreach my $handler (reverse(@{$HANDLERS->{$_signal}})) {

        my $sub = $handler->{callback};
        my $arg = $handler->{arguments};
        my $pid = $handler->{pid};

        if (not defined($pid) or $pid == $$ ) {

            $sub->(@$arg);
        }
    }
}

###
# register a signal handler.
#
# $_signal    - signal to be registered
# $_callback  - callback function to be registered (function ref)
# $_arguments - argument list handed over to the callback function (array ref)
# $_pid       - pid for which this handler is valid (or undef)
# <- the handler refernce to be used in deregister()
sub register {

    my $_signal    = shift;
    my $_callback  = shift;
    my $_arguments = shift;
    my $_pid       = shift;

    my $handler = {

        callback  => $_callback,
	pid       => $_pid,
        arguments => $_arguments,
    };

    push(@{$HANDLERS->{$_signal}}, $handler);

    $SIG{$_signal} = \&_handler;

    return $handler;
}

###
# deregister a signal handler.
#
# $_signal  - signal to be registered
# $_handler - argument list handed over to the callback function (array ref)
sub deregister {

    my $_signal  = shift;
    my $_handler = shift;

    my $handlers = $HANDLERS->{$_signal};

    my %index;
    @index{@$handlers} = (0..scalar(@$handlers));
    my $index = $index{$_handler};

    if (defined($index)) {

        splice(@$handlers, $index, 1);

        if (scalar(@$handlers) == 0) {

            $ENV{$_signal} = 'DEFAULT';
        }
    }
}

1;
