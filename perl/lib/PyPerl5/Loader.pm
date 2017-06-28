package PyPerl5::Loader;
use strict;
use warnings;

our $vm;


sub load {
    my $package = shift;
    my ($file, $namespace) = @_;
    my $ret;
    if (exists $INC{$file}) {
        return;
    }

    if(!$namespace){
        $namespace = "main";
    }

    my $eval = qq{ package $namespace; require q\0$file\0; package main; };
    {
        $ret = eval $eval;
    }

    die $@ if $@;
    return $ret
}

sub load_module {
    my $package = shift;
    my ($module, $args, $version) = @_;
    my ($option, $ret) = ('');

    my $file = "$module.pm";
    $file =~ s#::#/#g;
    if (exists $INC{$file}) {
        return;
    }

    my @import_list;
    if (ref $args eq 'ARRAY') {
        @import_list = @$args;
    } elsif (ref $args eq 'HASH') {
        @import_list = %$args;
    } elsif (defined $args) {
        @import_list = ($args);
    }

    if (defined $version) {
        if (@import_list) {
            $option = sprintf ' %s @import_list', $version;
        } else {
            $option = " $version";
        }
    } elsif (@import_list) {
        $option = ' @import_list';
    }

    my $eval = qq {use $module$option; package main; };
    {
        $ret = eval $eval;
    }

    die $@ if $@;
    return $ret
}

1;
