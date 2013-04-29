# Program: <FILE>
# Author:  <AUTHORNAME> <<AUTHOREMAIL>>
# Date:    <COMMITTERDATE>
# Ident:   <COMMITHASH>
# Branch:  <REFNAMES>
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package WorkerNsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;

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
# $_cfg - parameter hash where
# {
#   'agentinfo_args'   - arguments supplied to the agentinfo binary
#   'agentinfo_binary' - agentinfo binary to be executed
#   'ncp_args'         - arguments supplied to the ncp binary
#   'ncp_binary'       - ncp binary to be executed
#   'nexec_args'       - arguments supplied to the nexec binary
#   'nexec_binary'     - nexec binary to be executed
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_cfg = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{agentinfo_args}   = $_cfg->{agentinfo_args};
    $self->{agentinfo_binary} = $_cfg->{agentinfo_binary};
    $self->{nexec_args}       = $_cfg->{nexec_args};
    $self->{nexec_binary}     = $_cfg->{nexec_binary};
    $self->{ncp_args}         = $_cfg->{ncp_args};
    $self->{ncp_binary}       = $_cfg->{ncp_binary};

    $self->{MODINFO} = $MODINFO;
    return $self;
}

###
# copy a file using nsh to $_host.
#
# $_host   - the host the command should be exeuted on
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- (
#      $ret - the return code (-128 indicates too many parallel connections)
#      $out - command output
#    )
sub copy {

    my $_self   = shift;
    my $_host   = shift;
    my $_source = shift;
    my $_target = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my ($ret, $out) = $_self->error_handler(_("$_self->{agentinfo_binary} $_host"));
    return ($ret, $out) if (not $ret == 0);

    return $_self->error_handler(_("$_self->{ncp_binary} $_self->{ncp_args} $_source - //$_host/$_target"));
}

###
# execute the command using nsh on $_host.
#
# $_host    - the host the command should be exeuted on
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- (
#      $ret - the return code (-128 indicates too many parallel connections)
#      $out - command output
#    )
sub execute {

    my $_self    = shift;
    my $_host    = shift;
    my $_command = shift;
    my $_args    = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my ($ret, $out) = $_self->error_handler(_("$_self->{agentinfo_binary} $_host"));
    return ($ret, $out) if (not $ret == 0);

    return $_self->error_handler(_("$_self->{nexec_binary} $_self->{nexec_args} -n $_host $_command $_args"));
}

###
# delete a file using nsh on $_host.
#
# $_host - the host the command should be exeuted on
# $_file - the command that should be executed
# <- (
#      $ret - the return code (-128 indicates too many parallel connections)
#      $out - command output
#    )
sub delete {

    my $_self = shift;
    my $_host = shift;
    my $_file = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my ($ret, $out) = $_self->error_handler(_("$_self->{agentinfo_binary} $_host"));
    return ($ret, $out) if (not $ret == 0);

    return $_self->error_handler(_("$_self->{nexec_binary} $_self->{nexec_args} -n $_host rm -f \"$_file\""));
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

