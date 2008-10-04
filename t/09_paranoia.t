#!perl -w


use strict;
use Test::More tests => 6;

use instanceof;

no warnings;

BEGIN{
	package Foo;
	our @ISA = (undef, 1, [], \&new, 'Base');

	sub new{
		bless {} => shift;
	}
}

my $o = Foo->new();

ok  $o << 'Foo';
ok  $o << 'Base';
ok  $o << 'UNIVERSAL';

@Foo::ISA = ();

ok  $o << 'Foo';
ok!($o << 'Base');
ok  $o << 'UNIVERSAL';

