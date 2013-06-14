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

###
# this is the base module for all worker implementations and
# it is responsible for loading the available implementations
# at runtime.
#
# a worker implements a a single remote access mechanism like ssh
# which will be used to execute commands on the remote host,
# delete files on the remote host and to copy files to the remote host.
#
# derived modules must implement the following subs's
#
# - init($cfg)
# - execute($cmd, $args)
# - delete($file)
# - copy($source, $target)
#
# a derived module must call register() in BEGIN{}, otherwise it will not
# be available.
#
# a derived module must always write to $_self->{E} (STDERR) and
# $_self->{O} (STDOUT).
#
# all output produced by the derived worker modules must match the
# following format:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# this is the string which will be passed to the logger/filter implementations.
###

package NRun::Worker;

use strict;
use warnings;

use File::Basename;
use IPC::Open3;

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
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{hostname} = $_cfg->{hostname};

    $_self->{O} = \*STDOUT;
    $_self->{E} = \*STDERR;
}

###
# SIGTERM signal handler.
sub handler_term {

    my $_self = shift;
    my $_pid  = shift;

    if ($$_pid != -128) {

        kill(KILL => $$_pid);
    } else {
  
        $$_pid = "n/a";
    }

    print {$$_self->{O}} "$$_self->{hostname};stdout;" . time() . ";$$;$$_pid;exit;\"exit code $NRun::Constants::CODE_SIGTERM;\"\n";
    print {$$_self->{E}} "$$_self->{hostname};stderr;" . time() . ";$$;$$_pid;error;\"SIGTERM received\"\n";
}

###
# SIGINT signal handler.
sub handler_int {

    my $_self = shift;
    my $_pid  = shift;

    if ($$_pid != -128) {

        kill(KILL => $$_pid);
    } else {
  
        $$_pid = "n/a";
    }

    print {$$_self->{O}} "$$_self->{hostname};stdout;" . time() . ";$$;$$_pid;exit;\"exit code $NRun::Constants::CODE_SIGINT;\"\n";
    print {$$_self->{E}} "$$_self->{hostname};stderr;" . time() . ";$$;$$_pid;error;\"SIGINT received\"\n";
}


###
# SIGALRM signal handler.
sub handler_alrm {

    my $_self = shift;
    my $_pid  = shift;

    if ($$_pid != -128) {

        kill(KILL => $$_pid);
    } else {
  
        $$_pid = "n/a";
    }

    print {$$_self->{O}} "$$_self->{hostname};stdout;" . time() . ";$$;$$_pid;exit;\"exit code $NRun::Constants::CODE_SIGALRM;\"\n";
    print {$$_self->{E}} "$$_self->{hostname};stderr;" . time() . ";$$;$$_pid;error;\"SIGALRM received\"\n";
}

###
# execute $_cmd.
#
# command output will be formatted the following way, line by line:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# $_cmd - the command to be executed
# <- the return code 
sub do {

    my $_self = shift;
    my $_cmd  = shift;

    chomp($_cmd);

    my $pid = -128;

    my $handler_alrm = NRun::Signal::register('ALRM', \&handler_alrm, [ \$_self, \$pid ], $$);
    my $handler_int  = NRun::Signal::register('INT',  \&handler_int,  [ \$_self, \$pid ], $$);
    my $handler_term = NRun::Signal::register('TERM', \&handler_term, [ \$_self, \$pid ], $$);

    eval{

        $pid = open3(\*CMDIN, \*CMDOUT, \*CMDERR, "$_cmd");
    };
    if ($@) {

        NRun::Signal::deregister('ALRM', $handler_alrm);
        NRun::Signal::deregister('INT',  $handler_int);
        NRun::Signal::deregister('TERM', $handler_term);

        print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;debug;\"exec $_cmd\"\n";
        print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;error;\"$@\"\n";
        print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;n/a;exit;\"exit code $NRun::Constants::EXECUTION_FAILED\"\n";

        return $NRun::Constants::EXECUTION_FAILED;
    }
    
    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;$pid;debug;\"exec $_cmd\"\n";

    my $selector = IO::Select->new();
    $selector->add(\*CMDOUT, \*CMDERR);

    while (my @ready = $selector->can_read()) {

        foreach my $fh (@ready) {

            if (fileno($fh) == fileno(CMDOUT)) {

                while (my $line = <$fh>) {

                    chomp($line);
                    print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;$pid;output;\"$line\"\n";
                }
            } elsif (fileno($fh) == fileno(CMDERR)) {

                while (my $line = <$fh>) {

                    chomp($line);
                    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;$pid;output;\"$line\"\n";
                }
            }

            $selector->remove($fh) if eof($fh);
        }
    }
    close(CMDIN);
    close(CMDOUT);
    close(CMDERR);

    waitpid($pid, 0);

    print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;$pid;exit;\"exit code " . ($? >> 8) . "\"\n";

    NRun::Signal::deregister('ALRM', $handler_alrm);
    NRun::Signal::deregister('INT',  $handler_int);
    NRun::Signal::deregister('TERM', $handler_term);

    return ($? >> 8);
}

###
# send a message to stdout indicating that no more executions
# will be done by this worker.
#
# in fact, execution is still possible, but all output to stdout/stderrr
# will be suppressed.
#
# HOSTNAME;stdout;TSTAMP;PID;n/a;end;
# HOSTNAME;stderr;TSTAMP;PID;n/a;end;
sub end {

    my $_self   = shift;

    print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;n/a;end;\n";
    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;end;\n";

    open(NULL, ">/dev/null");

    $_self->{O} = \*NULL;
    $_self->{E} = \*NULL;
}

1;
