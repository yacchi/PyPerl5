package PyPerl5::Util;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/ run_under_python /;

sub run_under_python {
    no warnings 'once';
    return $PyPerl5::CALLED_FROM_PYTHON // '';
}

1;
