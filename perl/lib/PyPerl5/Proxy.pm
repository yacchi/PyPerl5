package PyPerl5::Proxy;

use 5.010;
use strict;
use warnings;
use Carp;
use overload
    '&{}'    => sub {
        my $self = shift;
        return sub {$self->__call__(@_)}
    },
    fallback => 1,
    #    '""'  => sub {"aaa"}
;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use PyPerl5 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [qw(
        py_get_object
        )] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

    );

our $VERSION = '__PY_PERL5_VERSION__';

require XSLoader;
XSLoader::load();

# Preloaded methods go here.
sub new {
    my $class = shift;
    if(ref $class && $class->isa(__PACKAGE__)) {
        my $self = $class->(@_);
        return $self;
    }else {
        my $class_name = $class;
        my ($py_object_ptr) = @_;
        my $self = bless {}, $class_name;
        $self->_attach_py_object_ptr($py_object_ptr);
        return $self;
    }
}

sub get_object {
    my $class = shift;
    my ($import_string) = @_;
    my ($module, $attribute) = ($import_string =~ /^(.+)\.([^\.]+)$/g);
    my $o = $class->_get_py_object($module, $attribute);
    return $o;
}

sub py_get_object {
    return __PACKAGE__->get_object(@_);
}

sub DESTROY {
    my $self = shift;
    $self->_detach_py_object_ptr();
}

sub __call__ {
    my $self = shift;
    return $self->exec('__call__', [@_]);
}

sub __str__ {
    my $self = shift;
    return $self->exec('__str__');
}

sub __repr__ {
    my $self = shift;
    return $self->exec('__repr__');
}

sub AUTOLOAD {
    my $self = shift;
    my ($pkg, $name) = (our $AUTOLOAD =~ /(.*)::([^:]+)$/);

    @_ = ($self, $name, [@_]);
    goto &exec;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PyPerl5::Proxy - Perl extension for blah blah blah

=head1 SYNOPSIS

  use PyPerl5::Proxy;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for PyPerl5, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

root, E<lt>root@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
