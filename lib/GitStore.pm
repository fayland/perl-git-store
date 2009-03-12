package GitStore;

use Moose;
use Git::PurePerl;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:FAYLAND';

has 'repo' => ( is => 'ro', isa => 'Str', required => 1 );
has 'branch' => ( is => 'rw', isa => 'Str', default => 'master' );

has 'git_perl' => (
    is => 'ro',
    isa => 'Git::PurePerl',
    lazy => 1,
    default => sub {
        Git::PurePerl->new( directory =>  shift->repo );
    }
);

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return { repo => $_[0] };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub store {
    my $self = shift;
    
}

sub commit {
    my $self = shift;
    
}



no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

GitStore - Git as versioned data store in Perl

=head1 SYNOPSIS

    use GitStore;

    my $gs = GitStore->new('/path/to/repo');
    $gs->store( 'users/matthias.yml', $obj );
    $gs->store( ['config', 'wiki.yml'], { hash_ref => 1 } );
    $gs->commit( 'your commit info here' );

=head1 DESCRIPTION

It is inspired by L<http://www.newartisans.com/2008/05/using-git-as-a-versioned-data-store-in-python.html>

Python binding - L<http://github.com/jwiegley/git-issues/tree/master>

Ruby binding - L<http://github.com/georgi/git_store/tree/master>

This module is mainly a port of the Ruby binding.

=head1 METHODS

=head2 new

=head2 store

=head2 commit

=head1 Git URL

L<http://github.com/fayland/perl-git-store/tree/master>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
