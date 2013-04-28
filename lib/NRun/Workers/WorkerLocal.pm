# Program: <FILE>
# Author:  <AUTHORNAME> <<AUTHOREMAIL>>
# Date:    <COMMITTERDATE>
# Ident:   <COMMITHASH>
# Branch:  <REFNAMES>
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package WorkerLocal;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;

our @ISA = qw(NRun::Worker);

###
# module specification
our $MODINFO = {

  'MODE' => "local",
  'DESC' => "execute the script locally, set TARGET_HOST on each execution",
};

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{MODINFO} = $MODINFO;
    return $self;
}

###
# execute the command locally and set environment variable TARGET_HOST
# to $_host.
#
# $_host - the host that should be used in TARGET_HOST
# $_opts - parameter hash where
# {
#   'command'   - the command to be exeuted
#   'arguments' - the arguments supplied to command
# }
# <- (
#      $ret - the return code
#      $out - command output
#    )
sub execute {

    my $_self = shift;
    my $_host = shift;
    my $_opts = shift;

    $ENV{"TARGET_HOST"} = $_host;

    return _("$_opts->{command} $_opts->{arguments}");
}

1;

