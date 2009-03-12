#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'GitStore' );
}

diag( "Testing GitStore $GitStore::VERSION, Perl $], $^X" );
