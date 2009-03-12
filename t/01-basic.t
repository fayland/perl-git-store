#!perl

use Test::More tests => 4;
use Git::PurePerl;
use Path::Class;
use GitStore;
use FindBin qw/$Bin/;

# init the test
my $directory = "$Bin/test";
dir($directory)->rmtree;
Git::PurePerl->init( directory => $directory );

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
$t = $gs->get("$file.txt");
is $t, $time;

$gs->commit;
$t = $gs->get("$file.txt");
is $t, $time;

# save for next file, different instance
$gs->store("committed.txt", 'Yes');
$gs->commit;
$gs->store("not_committed.txt", 'No');

1;