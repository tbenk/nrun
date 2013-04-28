# Program: <FILE>
# Author:  <AUTHORNAME> <<AUTHOREMAIL>>
# Date:    <COMMITTERDATE>
# Ident:   <COMMITHASH>
# Branch:  HEAD, origin/master, master
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package WorkerSsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;
use Net::Ping;

our @ISA = qw(NRun::Worker);

###
# module specification
our $MODINFO = {

  'MODE' => "ssh",
  'DESC' => "ssh based remote execution",
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
# execute the command using ssh on $_host.
#
# $_host - the host the command should be exeuted on
# $_opts - parameter hash where
# {
#   'command'    - the command to be exeuted
#   'arguments'  - arguments supplied to the command
#   'copy'       - copy command to target host before execution
#   'ssh_args'   - arguments supplied to the ssh binary
#   'scp_args'   - arguments supplied to the scp binary
#   'ssh_binary' - ssh binary to be executed
#   'scp_binary' - scp binary to be executed
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

    if (not (defined($_opts->{skip_ns_check}) or gethostbyname($_host))) {

      return (-254, "dns entry is missing");
    }

    if (not (defined($_opts->{skip_ping_check}) or Net::Ping->new()->ping($_host))) {

      return (-253, "not pinging");
    }

    if (not defined($_opts->{copy})) {

        ($ret, $out) = _("$_opts->{ssh_binary} $_opts->{ssh_args} root\@$_host $_opts->{command} $_opts->{arguments}");
    } else {

        my $command = basename($_opts->{command}) . "." . $$;
    
        ($ret, $out) = _("$_opts->{scp_binary} $_opts->{scp_args} $_opts->{command} root\@$_host:/tmp/$command");
        return ($ret, $out) if (not $ret == 0);
    
        ($ret, $out) = _("$_opts->{ssh_binary} $_opts->{ssh_args} root\@$_host chmod 755 /tmp/$command");
        return ($ret, $out) if (not $ret == 0);
    
        ($ret, $out) = _("$_opts->{ssh_binary} $_opts->{ssh_args} root\@$_host /tmp/$command $_opts->{arguments}");
        _("$_opts->{ssh_binary} $_opts->{ssh_args} root\@$_host rm /tmp/$command");
    }
    
    return ($ret, $out);
}

1;

