use 5.016003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME      => 'PyPerl5::Proxy',
    VERSION   => $ENV{PY_PERL5_VERSION},
    PREREQ_PM => {},                              # e.g., Module::Name => 1.1
    ($] >= 5.005 ?                                ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'lib/PyPerl5/Proxy.pm', # retrieve abstract from module
            AUTHOR     => 'root <root@localdomain>') : ()),
    LIBS      => [ '' ], # e.g., '-lm'
    # C                 => ['Proxy.cpp'],
    H         => [ '../src/ppport.h' ],
    # XS                => {
    #     'Proxy.xsp' => 'Proxy.cpp',
    # },
    # DEFINE            => '-b -o $@', # e.g., '-DHAVE_SOMETHING'
    DEFINE    => '-o $@',                               # e.g., '-DHAVE_SOMETHING'
    INC       => "-I. -I../src -I$ENV{PYTHON_INC_DIR}", # e.g., '-I. -I/usr/include/other'
    # Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
    OBJECT    => '$(O_FILES)', # link all the C files too
    OPTIMIZE  => '-O2',
    XSOPT     => '-C++',
    PM_FILTER => "perl -ple 's/__PY_PERL5_VERSION__/$ENV{PY_PERL5_VERSION}/g'",
);
