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
# copy a file to $_host.
#
# $_host   - the host the command should be exeuted on
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- (
#      $ret - the return code
#      $out - command output
#    )
sub copy {

    my $_self   = shift;
    my $_host   = shift;
    my $_source = shift;
    my $_target = shift;

    return (1, "not implemented");
}

###
# execute the command locally and set environment variable TARGET_HOST
# to $_host.
#
# $_host    - the host the command should be exeuted on
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- (
#      $ret - the return code
#      $out - command output
#    )
sub execute {

    my $_self    = shift;
    my $_host    = shift;
    my $_command = shift;
    my $_args    = shift;

    $ENV{"TARGET_HOST"} = $_host;

    return _("$_command $_args");
}

###
# delete a file on $_host.
#
# $_host - the host the command should be exeuted on
# $_file - the command that should be executed
# <- (
#      $ret - the return code
#      $out - command output
#    )
sub delete {

    my $_self = shift;
    my $_host = shift;
    my $_file = shift;

    return (1, "not implemented");
}

1;

