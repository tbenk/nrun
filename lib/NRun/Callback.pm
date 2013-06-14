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
# this package contains the callback sub's for nrun/nexec which 
# will be executed in the child's context.
###

package NRun::Callback;

use File::Temp qw(tempfile);

###
# ensure cleanup on TERM, INT and ALRM
sub handler_cleanup {

    my $_worker  = shift;
    my $_command = shift;
    my $_copy    = shift;

    $$_worker->end();

    if (defined($$_copy)) {

        $$_worker->delete($$_command) if (defined($$_copy));
    }
}

###
# callback function used by the dispatcher (nrun)
sub nrun {
    
    my $_worker    = shift;
    my $_command   = shift;
    my $_arguments = shift;
    my $_checks    = shift;
    my $_copy      = shift;

    my $handler_cleanup = NRun::Signal::register('TERM', \&handler_cleanup, [ \$_worker, \$_command, \$_copy ]);
    my $handler_cleanup = NRun::Signal::register('INT',  \&handler_cleanup, [ \$_worker, \$_command, \$_copy ]);
    my $handler_cleanup = NRun::Signal::register('ALRM', \&handler_cleanup, [ \$_worker, \$_command, \$_copy ]);

    foreach my $check (@{$_checks}) {

        if (not $check->execute()) {

            $_worker->end();
            return;
        }
    }

    if (defined($_copy)) {

        my $source = $_command;

        $_command = (tempfile(OPEN => 0, DIR => "/tmp"))[1] . "$$";

        if ($_worker->copy($source, $_command) != 0) {

            $_worker->end();
            return;
        }
    }

    $_worker->execute($_command, $_arguments);

    $_worker->end();

    if (defined($_copy)) {

        $_worker->delete($_command);
    }

    NRun::Signal::deregister('TERM', $handler_cleanup);
    NRun::Signal::deregister('INT',  $handler_cleanup);
    NRun::Signal::deregister('ALRM', $handler_cleanup);
}

###
# callback function used by the dispatcher (ncopy)
sub ncopy {
    
    my $_worker      = shift;
    my $_source      = shift;
    my $_destination = shift;
    my $_checks      = shift;

    foreach my $check (@{$_checks}) {

        if (not $check->execute()) {

            $_worker->end();
            return;
        }
    }

    $_worker->copy($_source, $_destination);

    $_worker->end();
}

1;
