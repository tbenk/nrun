# Program: <FILE>
# Author:  <AUTHORNAME> <<AUTHOREMAIL>>
# Date:    <COMMITTERDATE>
# Ident:   <COMMITHASH>
# Branch:  HEAD, origin/master, master
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package WorkerNsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;
use Net::Ping;

our @ISA = qw(NRun::Worker);

###
# module specification
our $MODINFO = {

  'MODE' => "nsh",
  'DESC' => "nsh based remote execution",
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
# execute the command using nsh on $_host.
#
# $_host - the host the command should be exeuted on
# $_opts - parameter hash where
# {
#   'command'          - the command to be exeuted
#   'arguments'        - arguments supplied to the command
#   'copy'             - copy command to target host before execution
#   'agentinfo_args'   - arguments supplied to the agentinfo binary
#   'nexec_args'       - arguments supplied to the nexec binary
#   'ncp_args'         - arguments supplied to the ncp binary
#   'agentinfo_binary' - agentinfo binary to be executed
#   'nexec_binary'     - nexec binary to be executed
#   'ncp_binary'       - ncp binary to be executed
# }
# <- (
#      $ret - the return code (-128 indicates too many parallel connections)
#      $out - command output
#    )
sub execute {

    my $_self = shift;
    my $_host = shift;
    my $_opts = shift;

    if (not (defined($_opts->{skip_ns_check}) or gethostbyname($_host))) {

      return (-254, "dns entry is missing");
    }

    if (not (defined($_opts->{skip_ping_check}) or Net::Ping->new()->ping($_host))) {

      return (-253, "not pinging");
    }

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my ($ret, $out) = $_self->error_handler(_("$_opts->{agentinfo_binary} $_host"));
    return ($ret, $out) if (not $ret == 0);

    if (not defined($_self->{copy})) {

        ($ret, $out) = $_self->error_handler(_("$_opts->{nexec_binary} $_opts->{nexec_args} -n $_host $_opts->{command} $_opts->{arguments}"));
    } else {

        my $command = basename($_opts->{command}) . "." . $$;

        ($ret, $out) = $_self->error_handler(_("$_opts->{ncp_binary} $_opts->{ncp_args} $_opts->{command} - //$_host/tmp/$command"));
        return ($ret, $out) if (not $ret == 0);

        ($ret, $out) = $_self->error_handler(_("chmod 755 //$_host/tmp/$command"));
        return ($ret, $out) if (not $ret == 0);

        ($ret, $out) = $_self->error_handler(_("$_opts->{nexec_binary} $_opts->{nexec_args} -n $_host /tmp/$command $_opts->{arguments}"));

        $_self->error_handler(_("$_opts->{nexec_binary} $_opts->{nexec_args} -n $_host rm /tmp/$command"));

    }

    return ($ret, $out);
}

###
# scan command output for nsh error messages.
#
# bladelogic seems to have a problem when doing too many parallel
# requests at once. If this is the case and the action fails for that
# reason, -128 is returned.
#
# $_ret - the return code
# $_out - the command output
# <- (
#      $ret - the return code (-128 indicates too many parallel connections)
#      $out - command output
#    )
sub error_handler {

    my $_self = shift;
    my $_ret  = shift;
    my $_out  = shift;

    # return -128 on messages indicating too many parallel connections
    if (   grep(/SSO Error: Error reading server greeting/,            $_out)
        or grep(/SSO Error: Could not load credential cache file/,     $_out)
        or grep(/SSL_connect/,                                         $_out)
        or grep(/nexec: Error accessing host .* Connection timed out/, $_out)
        or grep(/Unable to reach .* Connection timed out/,             $_out))
    {

        return (-128, $_out);
    }

    return ($_ret, $_out);
}

1;

