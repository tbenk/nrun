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

###
# module specification
our $MODINFO = {

  'MODE' => "",
  'DESC' => "",
};

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

    local $SIG{ALRM} = sub {

        kill(9, $pid);
        die "SIGALRM received (timeout)\n";
    };

    $pid = open(CMD, "$_cmd 2>&1 2>&1|") or die "$_cmd: $!\n"; 
    my @out = <CMD>;
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

