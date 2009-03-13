#!perl

use Test::More tests => 8;
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
$gs->set("$file.txt", $time);
my $t = $gs->get("$file.txt");
is $t, $time;

$gs->discard;
$t = $gs->get("$file.txt");
is $t, undef;

$gs->set("$file.txt", $time);
$gs->set(['dir', 'ref.txt'], { hash => 1, array => 2 } );
$t = $gs->get("$file.txt");
is $t, $time;

$gs->commit;
$t = $gs->get("$file.txt");
is $t, $time;
my $refval = $gs->get('dir/ref.txt');
is $refval->{hash}, 1;
is $refval->{array}, 2;

# after delete
$gs->delete("$file.txt");
$t = $gs->get("$file.txt");
is $t, undef;
$gs->remove('dir/ref.txt');
$refval = $gs->get('dir/ref.txt');
is $refval, undef;

# save for next file, different instance
$gs->set("committed.txt", 'Yes');
$gs->set("gitobj.txt", $gitobj );
$gs->commit;
$gs->set("not_committed.txt", 'No');

1;