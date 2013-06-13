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
# this module is responsible for the handover of the output of
# the different worker processes to the Filter/Logger
# implementations.
# 
# each worker prcess will be connected to this module using
# pipe()s.
#
# general workflow
#
# WORKER->SINK->FILTER
# or
# WORKER->SINK->LOGGER
package NRun::Sink;

use strict;
use warnings;

use IO::Select;

###
# create a new object.
sub new {

    my $_pkg = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this sink.
#
# $_cfg - parameter hash where
# {
#   'filters' - array reference of filter objects
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{filters} = $_cfg->{filters};

    $_self->{RDR1} = [];
    $_self->{RDR2} = [];
}

###
# create two additional pipes connected to this sink
# process. each child process needs it's own pipes.
#
# - must be called before each fork() 
# - must be called before connect() or disconnect().
# - must be called in the parent's context
sub pipe() {

    my $_self = shift;

    my ( $rdr1, $rdr2 );

    pipe($rdr1, $_self->{WRT1});
    pipe($rdr2, $_self->{WRT2});

    push(@{$_self->{RDR1}}, $rdr1);
    push(@{$_self->{RDR2}}, $rdr2);
}

###
# process data from the worker processes. 
#
# - must be called in the parent's context
sub process {

    my $_self = shift;

    close($_self->{WRT1});
    close($_self->{WRT2});
        
    my $selector = IO::Select->new();
    $selector->add(@{$_self->{RDR1}}, @{$_self->{RDR2}});
        
    while (my @ready = $selector->can_read()) {
        
        foreach my $fh (@ready) {
    
            my $line = <$fh>;

            foreach my $RDR1 (@{$_self->{RDR1}}) {

                last if (not defined($line));
                next if (not defined(fileno($RDR1)));

                if (fileno($fh) == fileno($RDR1)) {
        
                    foreach my $filter (@{$_self->{filters}}) {
    
                        $filter->stdout($line);
                    }
                }
            }

            foreach my $RDR2 (@{$_self->{RDR2}}) {

                last if (not defined($line));
                next if(not defined(fileno($RDR2)));

                if (fileno($fh) == fileno($RDR2)) {
        
                    foreach my $filter (@{$_self->{filters}}) {
    
                        $filter->stderr($line);
                    }
                }
            }

            if (eof($fh)) {
            
                $selector->remove($fh);
                close($fh);
            }
        }
    }
}

###
# connect STDOUT and STDERR from the current process to 
# this sink.
#
# - must be called in the child's context
sub connect() {

    my $_self = shift;

    return if (defined($_self->{OLDOUT}));

    foreach my $RDR1 (@{$_self->{RDR1}}) {

        close($RDR1);
    }

    foreach my $RDR2 (@{$_self->{RDR2}}) {

        close($RDR2);
    }

    open($_self->{OLDOUT}, ">&STDOUT") or die ("unable to save stdout: $!");
    open($_self->{OLDERR}, ">&STDERR") or die ("unable to save stderr: $!");

    open(STDOUT, ">&" . fileno($_self->{WRT1})) or die ("unable to redirect stdout: $!");
    open(STDERR, ">&" . fileno($_self->{WRT2})) or die ("unable to redirect stderr: $!");
}

###
# disconnect STDOUT and STDERR from the current process to 
# this sink.
#
# - must be called in the child's context
sub disconnect() {

    my $_self = shift;

    return if (not defined($_self->{OLDOUT}));

    open(STDOUT, ">&" . fileno($_self->{OLDOUT})) or die ("unable to restore stdout: $!");
    open(STDERR, ">&" . fileno($_self->{OLDERR})) or die ("unable to restore stderr: $!");

    delete($_self->{OLDOUT});
    delete($_self->{OLDERR});
}

1;
