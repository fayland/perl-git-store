#!perl

use Test::More; #tests => 6;
BEGIN {
    plan skip_all => 'Need a new Git::PurePerl in master';
};
use Git::PurePerl;
use Path::Class;
use GitStore;
use FindBin qw/$Bin/;

# init the test
my $directory = "$Bin/test";
dir($directory)->rmtree;
my $gitobj = Git::PurePerl->init( directory => $directory );

my $gs = GitStore->new($directory);

my $time = time();
my $file = rand();
$gs->store("$file.txt", $time);
my $t = $gs->get("$file.txt");
is $t, $time;

$gs->discard;
$t = $gs->get("$file.txt");
is $t, undef;

$gs->store("$file.txt", $time);
$gs->store(['dir', 'ref.txt'], { hash => 1, array => 2 } );
$t = $gs->get("$file.txt");
is $t, $time;

$gs->commit;
$t = $gs->get("$file.txt");
is $t, $time;
my $refval = $gs->get('dir/ref.txt');
is $refval->{hash}, 1;
is $refval->{array}, 2;

# save for next file, different instance
$gs->store("committed.txt", 'Yes');
$gs->store("gitobj.txt", $gitobj );
$gs->commit;
$gs->store("not_committed.txt", 'No');

1;