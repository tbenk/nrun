use ExtUtils::MakeMaker;
  
WriteMakefile (
    'NAME'             => 'nrun',
    'VERSION_FROM'     => 'lib/NRun/Version.pm',
    'INSTALLSCRIPT'    => 'blib/bin', 
    'EXE_FILES'        => [
        'bin/nrun',
        'bin/ncopy',
    ],
    'PREREQ_PM' => {
        "Date::Format" => 0,
    },
);

sub MY::postamble {

    my $postamble =
    "install :: etc/nrun.config\n" .
    "\tmkdir -p \$(INSTALL_BASE)/etc\n" .
    "\tcp etc/nrun.config \$(INSTALL_BASE)/etc/nrun.config\n";

    return $postamble;
}

