use ExtUtils::MakeMaker;
  
WriteMakefile (
    'NAME'               => 'nrun',
    'VERSION_FROM'       => 'lib/NRun/Version.pm',
    'EXE_FILES'          => [
        'bin/nrun',
        'bin/ncopy',
    ],
    'INSTALLSCRIPT' => 'blib/bin', 
    'MAN1PODS'           => {
        'misc/nrun.pod'  => 'blib/man1/nrun.1',
        'misc/ncopy.pod' => 'blib/man1/ncopy.1',
    },
);

sub MY::postamble {

    my $postamble =
    "install :: etc/nrun.config\n" .
    "\tmkdir -p \$(INSTALL_BASE)/etc\n" .
    "\tcp etc/nrun.config \$(INSTALL_BASE)/etc/nrun.config\n";

    return $postamble;
}

