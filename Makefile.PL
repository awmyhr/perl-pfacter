use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Pfacter',
    ABSTRACT        => 'Collect and display facts about the system',
    AUTHOR          => ['Scott Schneider <sschneid@gmail.com>', 'Andy MyHR <awmyhr@gmail.com'],
    VERSION_FROM    => 'bin/pfacter',
    PL_FILES        => {},
    PREREQ_PM       => { 'Getopt::Long' => 0, },
    EXE_FILES       => [ qw(bin/pfacter  bin/preport  bin/puppet-push-facts.sh	bin/puppet-push-report.sh) ],
    clean           => { FILES => "*~" },
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);

