package GitStore;

use Moose;
use Git::PurePerl;
use Storable qw(nfreeze thaw);
use Data::Dumper;

our $VERSION = '0.01_01';
our $AUTHORITY = 'cpan:FAYLAND';

has 'repo' => ( is => 'ro', isa => 'Str', required => 1 );
has 'branch' => ( is => 'rw', isa => 'Str', default => 'master' );

has 'head' => ( is => 'rw', isa => 'Str' );
has 'root' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'to_add' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

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
        my $tree = $commit->tree;
        my @directory_entries = $tree->directory_entries;
        my $root;
        foreach my $d ( @directory_entries ) {
            $root->{ $d->filename } = _cond_thaw( $d->object->content );
        }
        $self->root($root);
    }
}

sub get {
    my ( $self, $path ) = @_;
    
    $path = join('/', @$path) if ref $path eq 'ARRAY';

    if ( exists $self->to_add->{ $path } ) {
        return $self->to_add->{ $path };
    }
    if ( exists $self->root->{ $path } ) {
        return $self->root->{ $path };
    }
    
    return;
}

sub store {
    my ( $self, $path, $content ) = @_;
    
    $path = join('/', @$path) if ref $path eq 'ARRAY';

    $self->{to_add}->{$path} = $content;
}

sub commit {
    my $self = shift;
    
    return unless scalar keys %{$self->{to_add}};
    
    my @directory_entries;
    foreach my $path ( keys %{$self->{to_add}} ) {
        my $content = $self->to_add->{$path};
        $content = nfreeze( $content ) if ( ref $content );
        my $blob = Git::PurePerl::NewObject::Blob->new( content => $content );
        $self->git_perl->put_object($blob);
        my $de = Git::PurePerl::NewDirectoryEntry->new(
            mode     => '100644',
            filename => $path,
            sha1     => $blob->sha1,
        );
        push @directory_entries, $de;
    }

    my $tree = Git::PurePerl::NewObject::Tree->new(
        directory_entries => \@directory_entries,
    );
    $self->git_perl->put_object($tree);
    my $commit = Git::PurePerl::NewObject::Commit->new( tree => $tree->sha1 );
    $self->git_perl->put_object($commit);
    
    # reload
    $self->{to_add} = {};
    $self->load;
}

sub discard {
    my $self = shift;
    
    $self->{to_add} = {};
    $self->load;
}

sub _cond_thaw {
    my $data = shift;

    my $magic = eval { Storable::read_magic($data); };
    if ($magic && $magic->{major} && $magic->{major} >= 2 && $magic->{major} <= 5) {
        my $thawed = eval { Storable::thaw($data) };
        if ($@) {
            # false alarm... looked like a Storable, but wasn't.
            return $data;
        }
        return $thawed;
    } else {
        return $data;
    }
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
    $gs->store( 'users/obj.txt', $obj );
    $gs->store( ['config', 'wiki.txt'], { hash_ref => 1 } );
    $gs->commit();
    $gs->store( 'yyy/xxx.log', 'Log me' );
    $gs->discard();
    
    # later or in another pl
    my $val = $gs->get( 'user/obj.txt' ); # $val is the same as $obj
    my $val = $gs->get( 'config/wiki.txt' ); # $val is { hashref => 1 } );
    my $val = $gs->get( ['yyy', 'xxx.log' ] ); # $val is undef since discard
    

=head1 DESCRIPTION

It is inspired by the Python and Ruby binding. check SEE ALSO

=head1 METHODS

=head2 new

    GitStore->new('/path/to/repo');
    GitStore->new( repo => '/path/to/repo', branch => 'mybranch' );

=head2 store($path, $val)

    $gs->store( 'yyy/xxx.log', 'Log me' );
    $gs->store( ['config', 'wiki.txt'], { hash_ref => 1 } );
    $gs->store( 'users/obj.txt', $obj );

Store $val as a $path file in Git

$path can be String or ArrayRef

$val can be String or Ref[HashRef|ArrayRef|Ref[Ref]] or blessed Object

=head2 get($path)

    $gs->get( 'user/obj.txt' );
    $gs->get( ['yyy', 'xxx.log' ] );

Get $val from the $path file

$path can be String or ArrayRef

=head2 commit

    $gs->commit();

commit the B<store> changes into Git

=head2 discard

    $gs->discard();

discard the B<store> changes

=head1 INSTALL ISSUE NOW

It requires the Git::PurePerl master code. you must git clone it from L<http://github.com/acme/git-pureperl/tree/master> and install into your local dir.

The version would jump to 0.01 after a new L<Git::PurePerl> release.

=head1 SEE ALSO

=over 4

=item Article

L<http://www.newartisans.com/2008/05/using-git-as-a-versioned-data-store-in-python.html>

=item Python binding

L<http://github.com/jwiegley/git-issues/tree/master>

=item Ruby binding

L<http://github.com/georgi/git_store/tree/master>

=back

=head1 Git URL

L<http://github.com/fayland/perl-git-store/tree/master>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
