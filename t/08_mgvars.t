#!perl -w
use strict;

use Test::More tests => 10;

use Tie::Scalar;

use Scalar::Util::Ref qw(:check);

BEGIN{
	package Foo;
	sub new{
		bless {} => shift;
	}
}

tie my($x), 'Tie::StdScalar', [];

$x = [];

ok is_array_ref($x);
ok!is_hash_ref($x);

$x = '';

ok is_scalar_ref(\$x);
ok!is_array_ref($x);

$x = Foo->new();
tie my($class), 'Tie::StdScalar', 'Foo';

ok!is_hash_ref($x);

ok is_instance($x, $class);

$class = 'Bar';
ok!is_instance($x, $class);

$x = undef;
ok!is_instance($x, $class);
$x = {};
ok!is_instance($x, $class);
$x = '';
ok!is_instance($x, $class);

