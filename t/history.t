use strict;
use warnings;

use Test::More tests => 23;

use Git::PurePerl;
use Path::Class;
use GitStore;
use FindBin qw/$Bin/;

# init the test
my $directory = "$Bin/test";
dir($directory)->rmtree;
my $gitobj = Git::PurePerl->init( directory => $directory );

my $gs = GitStore->new($directory);

my $start_time = time;

my @content = qw/ alpha beta gamma delta /;

for ( 0..1 ) {
    $gs->set( 'foo/bar/baz', $content[$_] );
    $gs->commit("message for $content[$_]");
}

$gs->set( 'bar', { freeze => 'this' } );
$gs->commit( 'not important' );

for ( 2..3 ) {
    $gs->set( 'foo/bar/baz', $content[$_] );
    $gs->commit("message for $content[$_]");
}

my $end_time = time;

my @history = $gs->history('foo/bar/baz');

is @history => 4, '4 entries for foo/bar/baz';

my $last_time = $start_time;
my $i = 0;
for ( @history ) {
    isa_ok $_->timestamp, 'DateTime';
    cmp_ok $_->timestamp->epoch, '>=', $last_time, "commited after last one";
    cmp_ok $_->timestamp->epoch, '<=', $end_time, "commited before last time";
    $last_time = $_->timestamp->epoch;

    like $_->message => qr/^message for $content[$i]\s*$/, "message";
    is $_->content => $content[$i], "content";

    $i++
}

@history = $gs->history( 'bar' );

is @history => 1, 'only one commit for bar';

is_deeply scalar($history[0]->content) => { freeze => 'this' }, 
    "returns expanded object";

