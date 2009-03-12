#!perl

use Test::More tests => 1;

use GitStore;
my $gs = GitStore->new('E:/git/test');

$gs->store('aa.txt', 'XXXXXXXXXXXXXXXXX');
my $t = $gs->get('aa.txt');

diag $t;

ok(1);
