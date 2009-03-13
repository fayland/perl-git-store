#!perl

use Test::More;# tests => 4;
BEGIN {
    plan skip_all => 'Need a new Git::PurePerl in master';
};
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

1;