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

