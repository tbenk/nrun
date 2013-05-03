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

my $workers = {};

###
# module specification
our $MODINFO = {

  'MODE' => "",
  'DESC' => "",
};

###
# return all available worker modules
sub workers {

    return $workers;
}

###
# dynamically load all available login module
#
# $_cfg - option hash given to the submodules on creation
sub load_modules {

    my $_cfg = shift;

    my $basedir = dirname($INC{"NRun/Worker.pm"}) . "/Workers";

    opendir(DIR, $basedir) or die("$basedir: $!");
    while (my $module = readdir(DIR)) {

        if ($module =~ /\.pm$/i) {

            require "$basedir/$module";

            $module =~ s/\.pm$//i;

            my $object = $module->new($_cfg);
            $workers->{$object->mode()} = $object;
        }
    }
    close DIR;
}

###
# execute $_cmd. will die on SIGALRM.
#
# $_cmd -  the command to be executed
# <- (
#      $ret - the return code
#      $out - command output (joined stderr and stdout)
#    )
sub _ {

    my $_cmd = shift;

    my $pid = -128;
    my @out;

    local $SIG{INT} = sub {

        kill(9, $pid);
        push(@out, "SIGINT received\n");
        die join("", @out);
    };

    local $SIG{ALRM} = sub {

        kill(9, $pid);
        push(@out, "SIGALRM received (timeout)\n");
        die join("", @out);
    };

    $pid = open(CMD, "$_cmd 2>&1 2>&1|") or die "$_cmd: $!\n"; 
    while (my $line = <CMD>) {
    
       push(@out, $line);
    }
    close(CMD);

    return ($? >> 8, join("", @out));
}

sub mode {

    my $_self = shift;
    return $_self->{MODINFO}->{MODE};
}

sub desc {

    my $_self = shift;
    return $_self->{MODINFO}->{DESC};
}

1;

