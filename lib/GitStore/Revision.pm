package GitStore::Revision;
#ABSTRACT: the state of a given path for a specific commit

=head1 SYNOPSIS

   use GitStore;

   my $gs = GitStore->new('/path/to/repo');

   my @history = $gs->history( 'path/to/object' );

   for my $rev ( @history ) {
        say "modified at: ", $rev->timestamp;
        say "commit message was: ", $rev->message;
        say "===\n", $rev->content;
   }

=head1 DESCRIPTION

Represents an object in a  L<GitStore> at a specific commit.

=cut

use 5.10.0;

use strict;
use warnings;

use Moose;

use GitStore;
use DateTime;

=head1 METHODS

=head2 commit

Returns the SHA-1 of the commit.

=cut

has commit => (
    is => 'ro',
    required => 1,
);

=head2 path

Returns the path of the L<GitStore> object.

=cut

has path => (
    is => 'ro',
    required => 1,
);

has gitstore => (
    is => 'ro',
    isa => 'GitStore',
    required => 1,
    handles => {
        git_repo => 'git_repo'
    },
);

=head2 timestamp

Returns the commit time of the revision as a L<DateTime> object.

=cut

sub timestamp {
    my $self = shift;

    return DateTime->from_epoch( epoch =>
    ($self->git_repo->run( 'show', '--pretty=format:%at', $self->commit ))[0] );
}

=head2 message

Returns the commit message of the revision.  Note that the message might have
additional trailing carriage returns.

=cut

sub message {
    my $self = shift;

    ( my $comment = $self->git_repo->run( 'show', '--pretty=format:%B',
            $self->commit ) )
        =~ s/^diff --git.*//sm;

    return $comment;
}

=head2 content

Returns the content of the object.  If the object is a frozen ref, the
structure will be returned, like for `GitStore`'s `get()`.

=cut

sub content {
    my $self = shift;

    GitStore::_cond_thaw(
        scalar $self->git_repo->run('show', join ':', $self->commit, $self->path)
    );
}


__PACKAGE__->meta->make_immutable;
1;
