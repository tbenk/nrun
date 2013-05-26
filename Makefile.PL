use ExtUtils::MakeMaker;
  
WriteMakefile (
    'NAME'             => 'App::nrun',
    'VERSION_FROM'     => 'lib/NRun/Version.pm',
    'INSTALLSCRIPT'    => 'blib/bin', 
    'EXE_FILES'        => [
        'bin/nrun',
        'bin/ncopy',
    ],
    'PREREQ_PM' => {
        "Date::Format" => 0,
        "YAML"         => 0,
    },
);

sub MY::postamble {

    my $postamble =
    "install :: etc/nrunrc\n" .
    "\tmkdir -p \$(INSTALL_BASE)/etc\n" .
    "\tcp etc/nrunrc \$(INSTALL_BASE)/etc/nrunrc\n";

    return $postamble;
}

