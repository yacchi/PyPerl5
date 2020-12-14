package PyPerl5::Boolean;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw/ true false /;

use overload (
    '""' => \&string,
    bool => \&bool,
    '0+' => \&bool,
    '!' => \&negate,
    fallback => 1
);

our $true  = __PACKAGE__->new(1);

our $false = __PACKAGE__->new(0);

sub true { $true }

sub false { $false }

sub null { undef }

sub new {
    my ($class, $value) = @_;
    return bless \$value, $class;
}

sub bool {
    my $self = shift;
    return $$self;
}

sub negate {
    my $self = shift;
    return $$self ? $false : $true;
}

sub string {
    my $self = shift;
    return $$self ? 'true' : 'false';
}

sub is_bool {
    my $self = shift;
    defined $self && UNIVERSAL::isa($self, __PACKAGE__);
}

sub TO_JSON {
    my $self = shift;
    return $$self ? \1 : \0;
}

1;
