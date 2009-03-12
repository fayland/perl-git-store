#!perl

use Test::More tests => 2;
use FindBin qw/$Bin/;
use GitStore;

# init the test
my $directory = "$Bin/test";

my $gs = GitStore->new($directory);

# from 02-basic.t
my $val = $gs->get("committed.txt");
is $val, 'Yes';
$val = $gs->get("not_committed.txt");
is $val, undef;

1;