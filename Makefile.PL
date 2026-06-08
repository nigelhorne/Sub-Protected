use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Sub::Protected',
    AUTHOR           => 'Nigel Horne <nigel.horne@gmail.com>',
    VERSION_FROM     => 'lib/Sub/Protected.pm',
    ABSTRACT_FROM    => 'lib/Sub/Protected.pm',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.008',
    PREREQ_PM        => {
        'Attribute::Handlers' => 0,
        'Carp'                => 0,
    },
    TEST_REQUIRES    => {
        'Test::Most'      => 0,
        'Test::Exception' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/njh/Sub-Protected.git',
            },
        },
    },
);
