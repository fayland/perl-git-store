package GitStore;

use Moose;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:FAYLAND';

has 'repo' => ( is => 'ro', isa => 'Str', required => 1 );

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return { repo => $_[0] };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

1;
__END__

=head1 NAME

GitStore - Git as versioned data store in Perl

=head1 SYNOPSIS

    use GitStore;

    my $store = GitStore->new('/path/to/repo');
    

=head1 DESCRIPTION

It is inspired by L<http://www.newartisans.com/2008/05/using-git-as-a-versioned-data-store-in-python.html>

Python binding - L<http://github.com/jwiegley/git-issues/tree/master>

Ruby binding - L<http://github.com/georgi/git_store/tree/master>

=head1 Git URL

L<http://github.com/fayland/perl-git-store/tree/master>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
