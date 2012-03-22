package GitStore;

use Moose;
use Moose::Util::TypeConstraints;
use Git::PurePerl;
use Storable qw(nfreeze thaw);

our $VERSION = '0.06';
our $AUTHORITY = 'cpan:FAYLAND';

subtype 'PurePerlActor' =>
    as 'Git::PurePerl::Actor';

coerce PurePerlActor 
    => from 'Str'
    => via { 
    s/<(.*?)>//;
    Git::PurePerl::Actor->new( name => $_, email => $1 );
};

has 'repo' => ( is => 'ro', isa => 'Str', required => 1 );
has 'branch' => ( is => 'rw', isa => 'Str', default => 'master' );
has author => ( 
    is => 'rw', 
    isa => 'PurePerlActor',  
    default => sub { 
        Git::PurePerl::Actor->new( 
            name  => 'anonymous', 
            email => 'anon@127.0.0.1' 
        );
} );


has 'head_directory_entries' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );
has 'root' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'to_add' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'to_delete' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

has 'git' => (
    is => 'ro',
    isa => 'Git::PurePerl',
    lazy => 1,
    default => sub {
        my $repo = shift->repo;
        return Git::PurePerl->new( gitdir => $repo ) if $repo =~ m/\.git$/;
        return Git::PurePerl->new( directory => $repo );
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
    
    my $head = $self->git->ref_sha1('refs/heads/' . $self->branch);
    if ( $head ) {
        my $commit = $self->git->get_object($head);
        my $tree = $commit->tree;
        my @directory_entries = $tree->directory_entries;
        $self->head_directory_entries(\@directory_entries); # for delete
        my $root = {};
        foreach my $d ( @directory_entries ) {
            $root->{ $d->filename } = _cond_thaw( $d->object->content );
        }
        $self->root($root);
    }
}

sub get {
    my ( $self, $path ) = @_;
    
    $path = join('/', @$path) if ref $path eq 'ARRAY';

    if ( grep { $_ eq $path } @{$self->to_delete} ) {
        return;
    }
    if ( exists $self->to_add->{ $path } ) {
        return $self->to_add->{ $path };
    }
    if ( exists $self->root->{ $path } ) {
        return $self->root->{ $path };
    }
    
    return;
}

sub set {
    my ( $self, $path, $content ) = @_;
    
    $path = join('/', @$path) if ref $path eq 'ARRAY';
    $self->{to_add}->{$path} = $content;
}

*remove = \&delete;
sub delete {
    my ( $self, $path ) = @_;
    
    $path = join('/', @$path) if ref $path eq 'ARRAY';
    push @{$self->{to_delete}}, $path;
    
}

sub commit {
    my ( $self, $message ) = @_;
    
    return unless ( scalar keys %{$self->{to_add}} or scalar @{$self->to_delete} );

    my @new_de;
    my @directory_entries = @{ $self->head_directory_entries };
    # remove those need deleted or added
    foreach my $d ( @directory_entries ) {
        next if ( grep { $d->filename eq $_ } @{ $self->to_delete } );
        next if ( grep { $d->filename eq $_ } keys %{ $self->to_add } );
        push @new_de, Git::PurePerl::NewDirectoryEntry->new(
            mode     => '100644',
            filename => $d->filename,
            sha1     => $d->sha1,
        );;
    }
    # for add those new
    foreach my $path ( keys %{$self->{to_add}} ) {
        my $content = $self->to_add->{$path};
        $content = nfreeze( $content ) if ( ref $content );
        my $blob = Git::PurePerl::NewObject::Blob->new( content => $content );
        $self->git->put_object($blob);
        my $de = Git::PurePerl::NewDirectoryEntry->new(
            mode     => '100644',
            filename => $path,
            sha1     => $blob->sha1,
        );
        push @new_de, $de;
    }
    
    # commit
    my $tree = Git::PurePerl::NewObject::Tree->new(
        directory_entries => \@new_de,
    );
    $self->git->put_object($tree);
    
    my $timestamp = DateTime->now;
    my $content = $self->_build_my_content( $tree->sha1, $message || 'Your Comments Here' );
    my $commit = Git::PurePerl::NewObject::Commit->new(
        tree => $tree->sha1,
        content => $content,
        author => $self->author,
        committer => $self->author,
        comment => '',
        authored_time  => $timestamp,
        committed_time => $timestamp,
    );
    $self->git->put_object($commit);

    # reload
    $self->{to_add} = {};
    $self->{to_delete} = [];
    $self->load;
}

sub discard {
    my $self = shift;
    
    $self->{to_add} = {};
    $self->{to_delete} = [];
    $self->load;
}

sub _build_my_content {
    my ( $self, $tree, $message ) = @_;
    
    my $author = $self->author->name . " <" . $self->author->email . ">";
    my $time = time();
    
    my $content;
    $content .= "tree $tree\n";
    $content .= "author $author $time +0000\n";
    $content .= "committer $author $time +0000\n";
    $content .= "\n";
    $content .= "$message\n";
    return $content;
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
    $gs->set( 'users/obj.txt', $obj );
    $gs->set( ['config', 'wiki.txt'], { hash_ref => 1 } );
    $gs->commit();
    $gs->set( 'yyy/xxx.log', 'Log me' );
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
    GitStore->new( repo => '/path/to/repo', author => 'Someone Unknown <unknown\@what.com>' );

=over 4

=item repo

your git dir (without .git)

=item branch

your branch name, default is 'master'

=item author

It is used in the commit info

=back

=head2 set($path, $val)

    $gs->set( 'yyy/xxx.log', 'Log me' );
    $gs->set( ['config', 'wiki.txt'], { hash_ref => 1 } );
    $gs->set( 'users/obj.txt', $obj );

Store $val as a $path file in Git

$path can be String or ArrayRef

$val can be String or Ref[HashRef|ArrayRef|Ref[Ref]] or blessed Object

=head2 get($path)

    $gs->get( 'user/obj.txt' );
    $gs->get( ['yyy', 'xxx.log' ] );

Get $val from the $path file

$path can be String or ArrayRef

=head2 delete($path)

=head2 remove($path)

remove $path from Git store

=head2 commit

    $gs->commit();
    $gs->commit('Your Comments Here');

commit the B<set> changes into Git

=head2 discard

    $gs->discard();

discard the B<set> changes

=head1 FAQ

=head2 why the files are B<not> there?

run

    git checkout

=head2 any example?

    # if you just need a local repo, that's all you need.
    mkdir sandbox
    cd sandbox
    git init
    # use GitStore->new('/path/to/this/sandbox')
    # set something
    git checkout
    
    # follows are for remote git url
    git remote add origin git@github.com:fayland/sandbox2.git
    git push origin master
    # do more GitStore->new('/path/to/this/sandbox') later
    git checkout
    git pull origin master
    git push

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

Itsy bitsy contribution by Yanick Champoux, C<< <yanick@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009, 2010 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
