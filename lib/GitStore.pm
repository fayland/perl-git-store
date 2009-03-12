package GitStore;

use Moose;
use Git::PurePerl;
use Data::Dumper;

our $VERSION = '0.01';
our $AUTHORITY = 'cpan:FAYLAND';

has 'repo' => ( is => 'ro', isa => 'Str', required => 1 );
has 'branch' => ( is => 'rw', isa => 'Str', default => 'master' );

has 'head' => ( is => 'rw', isa => 'Str' );
has 'root' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'git_perl' => (
    is => 'ro',
    isa => 'Git::PurePerl',
    lazy => 1,
    default => sub {
        Git::PurePerl->new( directory =>  shift->repo );
    }
);

sub BUILD {
    my $self = shift;
    
    $self->load();
    
}

sub BUILDARGS {
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        return { repo => $_[0] };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

# Load the current head version from repository. 
sub load {
    my $self = shift;
    
    $self->{head} = $self->git_perl->ref_sha1('refs/heads/' . $self->branch);
    if ( $self->{head} ) {
        my $commit = $self->git_perl->ref('refs/heads/' . $self->branch);
        my $root = $self->root;
        $root->{id} = $commit->tree_sha1;
        $root->{data} = $commit->content;
        $root->{tree} = $commit->tree;
        $self->root($root);
    }
}

sub get {
    my ( $self, $path ) = @_;
    
    $path = join('/', @$path) if ref $path eq 'ARRAY';
    
    my $tree = $self->root->{tree};
    my @directory_entries = $tree->directory_entries;
    foreach my $d ( @directory_entries ) {
        if ( $d->filename eq $path ) {
            return $d->object->content;
        }
    }
    return;
}

sub store {
    my ( $self, $path, $content ) = @_;
    
    $path = join('/', @$path) if ref $path eq 'ARRAY';
    
    my $tree = $self->root->{tree};

    my $blob = Git::PurePerl::NewObject::Blob->new( content => $content );
    $self->git_perl->put_object($blob);
    my $de = Git::PurePerl::NewDirectoryEntry->new(
        mode     => '100644',
        filename => $path,
        sha1     => $blob->sha1,
    );
    my $tree2 = Git::PurePerl::NewObject::Tree->new(
        directory_entries => [$de],
    );
    $self->git_perl->put_object($tree2);
    
    # how to store $tree2 into $self->root?
}

sub commit {
    my $self = shift;
    
    # XXX? need check if changed
    my $tree = $self->root->{tree};
    my $commit = Git::PurePerl::NewObject::Commit->new( tree => $tree->sha1 );
    $self->git_perl->put_object($commit);
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
