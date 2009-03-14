#!perl

use Test::More tests => 4;
use FindBin qw/$Bin/;
use GitStore;
use Path::Class;

# init the test
my $directory = "$Bin/test";

my $gs = GitStore->new($directory);

# from 02-basic.t
my $val = $gs->get("committed.txt");
is $val, 'Yes';
$val = $gs->get("not_committed.txt");
is $val, undef;
my $gitobj = $gs->get("gitobj.txt");
isa_ok($gitobj, "Git::PurePerl");
is dir($gitobj->directory)->as_foreign('Unix'), dir($directory)->as_foreign('Unix');

# for 03-next-next.t
$gs->delete("committed.txt");
$gs->set("committed2.txt", 'Yes');
$gs->commit();

1;