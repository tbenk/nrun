# Program: <FILE>
# Author:  <AUTHORNAME> <<AUTHOREMAIL>>
# Date:    <COMMITTERDATE>
# Ident:   <COMMITHASH>
# Branch:  <REFNAMES>
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package WorkerRsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;
use Net::Ping;

our @ISA = qw(NRun::Worker);

###
# module specification
our $MODINFO = {

  'MODE' => "rsh",
  'DESC' => "rsh based remote execution",
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
# execute the command using rsh on $_host.
#
# $_host - the host the command should be exeuted on
# $_opts - parameter hash where
# {
#   'command'    - the command to be exeuted
#   'arguments'  - arguments supplied to the command
#   'copy'       - copy command to target host before execution
#   'rsh_args'   - arguments supplied to the rsh binary
#   'rcp_args'   - arguments supplied to the rcp binary
#   'rsh_binary' - rsh binary to be executed
#   'rcp_binary' - rcp binary to be executed
# }
# <- (
#      $ret - the return code
#      $out - command output
#    )
sub execute {

    my $_self = shift;
    my $_host = shift;
    my $_opts = shift;

    my ($ret, $out);

    if (not gethostbyname($_host)) {

      return (-254, "dns entry is missing");
    }

    if (not Net::Ping->new()->ping($_host)) {

      return (-253, "not pinging");
    }

    if (not defined($_opts->{copy})) {

        ($ret, $out) = _("$_opts->{rsh_binary} $_opts->{rsh_args} root\@$_host $_opts->{command} $_opts->{arguments}");
    } else {

        my $command = basename($_opts->{command}) . "." . $$;
    
        ($ret, $out) = _("$_opts->{rcp_binary} $_opts->{rcp_args} $_opts->{command} root\@$_host:/tmp/$command");
        return ($ret, $out) if (not $ret == 0);
    
        ($ret, $out) = _("$_opts->{rsh_binary} $_opts->{rsh_args} root\@$_host chmod 755 /tmp/$command");
        return ($ret, $out) if (not $ret == 0);
    
        ($ret, $out) = _("$_opts->{rsh_binary} $_opts->{rsh_args} root\@$_host /tmp/$command $_opts->{arguments}");
        _("$_opts->{rsh_binary} $_opts->{rsh_args} root\@$_host rm /tmp/$command");
    }
    
    return ($ret, $out);
}

1;

