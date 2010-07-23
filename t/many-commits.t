
use strict;
use warnings;

use Test::More tests => 2;                      # last test to print

use Git::PurePerl;
use Path::Class;
use GitStore;
use FindBin qw/$Bin/;

# init the test
my $directory = "$Bin/test";
dir($directory)->rmtree;
my $gitobj = Git::PurePerl->init( directory => $directory );

my $gs = GitStore->new($directory);

for ( qw/ alpha beta / ) {
    $gs->set( 'foo', $_ );
    $gs->commit($_);
}

my $commit = $gitobj->master;

is $commit->comment => 'beta';

$commit = $commit->parent;

is $commit->comment => 'alpha';


