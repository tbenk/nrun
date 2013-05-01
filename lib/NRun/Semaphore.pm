# Program: <FILE>
# Author:  <AUTHORNAME> <<AUTHOREMAIL>>
# Date:    <COMMITTERDATE>
# Ident:   <COMMITHASH>
# Branch:  <BRANCH>
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package NRun::Semaphore;

use strict;
use warnings;

use IPC::Semaphore;
use IPC::SysV qw(IPC_CREAT);
use Time::HiRes qw(usleep);

# ensure DESTROY() is called
$SIG{INT}  = sub { die("caught SIGINT\n")  };
$SIG{TERM} = sub { die("caught SIGTERM\n") }; 
$SIG{ABRT} = sub { die("caught SIGABRT\n") }; 
$SIG{QUIT} = sub { die("caught SIGQUIT\n") }; 

###
# create a new object.
#
# $_obj - parameter hash where
# {
#   'key' => semaphore key
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{key} = $_obj->{key};

    $self->{semaphore} = new IPC::Semaphore($self->{key}, 1, 0777 | IPC_CREAT);

    return $self;
}

###
# set a global lock. will block until the global lock could be set.
#
# <- returns 0 on failure and 1 on success
sub lock {

    my $_self = shift;

    usleep(10) while ($_self->{semaphore}->getval(0));

    return $_self->{semaphore}->setval(0, 1);
}

###
# unset a global lock.
#
# <- returns 0 on failure and 1 on success
sub unlock {

    my $_self = shift;

    return $_self->{semaphore}->setval(0, 0);
}

###
# remove the semaphore.
sub DESTROY {

    my $_self = shift;

    # $self->{semaphore} is undef in DESTROY() - recreate the semaphore for deletion
    $_self->{semaphore} = new IPC::Semaphore($_self->{key}, 1, 0777 | IPC_CREAT);

    $_self->{semaphore}->remove() if (defined($_self->{semaphore}));
}

1;

