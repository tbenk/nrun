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
use NRun::Signal;
use NRun::Constants;

###
# automagically load all available modules
INIT {

    my $basedir = dirname($INC{"NRun/Worker.pm"}) . "/Workers";

    opendir(DIR, $basedir) or die("$basedir: $!");
    while (my $module = readdir(DIR)) {

        if ($module =~ /\.pm$/i) {

            require "$basedir/$module";
        }
    }
    close DIR;
}

###
# all available workers will be registered here
my $workers = {};

###
# will be called by the worker modules on INIT.
#
# $_cfg - parameter hash where
# {
#   'MODE' - mode name
#   'DESC' - mode description
#   'NAME' - module name
# }
sub register {

    my $_cfg = shift;

    $workers->{$_cfg->{MODE}} = $_cfg;
}

###
# return all available worker modules
sub workers {

    return $workers;
}

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this worker module.
#
# $_cfg - parameter hash where
# {
#   'hostname' - hostname this worker should act on
#   'dumper'   - dumper object
#   'logger'   - logger object
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{hostname} = $_cfg->{hostname};
    $_self->{dumper}   = $_cfg->{dumper};
    $_self->{logger}   = $_cfg->{logger};
}

###
# signal handler.
sub handler {

    my $_pid  = shift;

    if (defined($$_pid) and $$_pid != -128) {

        kill(KILL => $$_pid);
    }
}

###
# execute $_cmd.
#
# $_cmd -  the command to be executed
# <- (
#      $out - command output
#      $ret - the return code (-128 indicates too many parallel connections)
#    )
sub do {

    my $_self = shift;
    my $_cmd  = shift;

    my $pid = -128;
    my @out = ();

    my $handler_alrm = NRun::Signal::register('ALRM', \&handler, [ \$pid ]);
    my $handler_int  = NRun::Signal::register('INT',  \&handler, [ \$pid ]);
    my $handler_term = NRun::Signal::register('TERM', \&handler, [ \$pid ]);

    $pid = open(CMD, "$_cmd 2>&1 2>&1|");
    if (not defined($pid)) {

        $_self->{dumper}->push("$_cmd: $!\n") if (defined($_self->{dumper}));
        $_self->{logger}->push("$_cmd: $!\n") if (defined($_self->{logger}));
        $_self->{dumper}->code($NRun::Constants::EXECUTION_FAILED) if (defined($_self->{dumper}));
        $_self->{logger}->code($NRun::Constants::EXECUTION_FAILED) if (defined($_self->{logger}));

        NRun::Signal::deregister('ALRM', $handler_alrm);
        NRun::Signal::deregister('INT',  $handler_int);
        NRun::Signal::deregister('TERM', $handler_term);

        return ( "$_cmd: $!\n", $NRun::Constants::EXECUTION_FAILED );
    }
    
    $_self->{dumper}->command("($pid) $_cmd") if (defined($_self->{dumper}));
    $_self->{logger}->command("($pid) $_cmd") if (defined($_self->{logger}));
    while (my $line = <CMD>) {
    
        $_self->{dumper}->push($line) if (defined($_self->{dumper}));
        $_self->{logger}->push($line) if (defined($_self->{logger}));
        push(@out, $line);
    }
    close(CMD);
    $_self->{dumper}->command() if (defined($_self->{dumper}));
    $_self->{logger}->command() if (defined($_self->{logger}));

    $_self->{dumper}->code($? >> 8) if (defined($_self->{dumper}));
    $_self->{logger}->code($? >> 8) if (defined($_self->{logger}));

    NRun::Signal::deregister('ALRM', $handler_alrm);
    NRun::Signal::deregister('INT',  $handler_int);
    NRun::Signal::deregister('TERM', $handler_term);


    return ( join("", @out), $? >> 8 );
}

###
# must be called at end of execution.
#
# global destruction in DESTROY is not safe
sub destroy {

    my $_self = shift;

    $_self->{dumper}->destroy() if (defined($_self->{dumper}));
    $_self->{logger}->destroy() if (defined($_self->{logger}));
}

###
# do some general checks.
#
# - ping check (will be checked if $_self->{skip_ns_check})
# - dns check (will be checked if $_self->{skip_dns_check)
#
# <- 1 on success and 0 on error
sub pre_check {

    my $_self = shift; 

    if (not (defined($_self->{skip_ns_check}) or gethostbyname($_self->{hostname}))) {

        $_self->{dumper}->push("dns entry is missing") if (defined($_self->{dumper}));
        $_self->{logger}->push("dns entry is missing") if (defined($_self->{logger}));
        $_self->{dumper}->code($NRun::Constants::MISSING_DNS_ENTRY) if (defined($_self->{dumper}));
        $_self->{logger}->code($NRun::Constants::MISSING_DNS_ENTRY) if (defined($_self->{logger}));

        return 0;
    }

    if (not (defined($_self->{skip_ping_check}) or Net::Ping->new()->ping($_self->{hostname}))) {

        $_self->{dumper}->push("not pinging") if (defined($_self->{dumper}));
        $_self->{logger}->push("not pinging") if (defined($_self->{logger}));
        $_self->{dumper}->code($NRun::Constants::PING_FAILED) if (defined($_self->{dumper}));
        $_self->{logger}->code($NRun::Constants::PING_FAILED) if (defined($_self->{logger}));

        return 0;
    }

    return 1;
}

1;

