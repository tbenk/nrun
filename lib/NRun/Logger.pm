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
# Branch:  <BRANCH>
#
# <CHANGELOG:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s>
#

package NRun::Logger;

use strict;
use warnings;

use File::Path;
use NRun::Semaphore;

my $SEMAPHORE = NRun::Semaphore->new({key => int(rand(100000))});

###
# create a new object.
#
# $_obj - parameter hash where
# {
#   'basedir' - the basedir the logs should be written to
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{basedir} = $_obj->{basedir};

    mkpath("$self->{basedir}/hosts");

    unlink("$self->{basedir}/../latest");
    symlink("$self->{basedir}", "$self->{basedir}/../latest");

    return $self;
}

###
# log the output
#
# $_host - the host this result belongs to
# $_ret  - the script return code
# $_out  - the script output
sub log {

    my $_self = shift;
    my $_host = shift;
    my $_ret  = shift;
    my $_out  = shift;

    $SEMAPHORE->lock();

    open(RES, ">>$_self->{basedir}/results.log")
      or die("$_self->{basedir}/results.log: $!");

    open(LOG, ">>$_self->{basedir}/hosts/$_host.log")
      or die("$_self->{basedir}/$_host.log: $!");

    open(OUT, ">>$_self->{basedir}/output.log")
      or die("$_self->{basedir}/output.log: $!");

    print RES "$_host; exit code $_ret; $_self->{basedir}/hosts/$_host.log\n";

    print LOG "$_out";

    $_out =~ s/^/$_host: /gms;

    chomp($_out);
    $_out .= "\n";    # ensure newline at end of line

    print OUT $_out;

    close(OUT);
    close(RES);
    close(LOG);

    $SEMAPHORE->unlock();
}

1;

