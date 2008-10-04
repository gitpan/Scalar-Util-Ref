#!perl -w
use strict;
use warnings FATAL => 'all';

use Benchmark qw(:all);

use Params::Util qw(_ARRAY0);
use Scalar::Util::Ref qw(:all);

my $o = [];

print "Params::Util::_ARRAY0() vs Scalar::Util::Ref::array_ref()\n",
	"\tfor an ARRAY reference\n";
cmpthese timethese -1 => {
	'_ARRAY0' => sub{
		# reftype($o) returns undef if $o is not a reference
		for(1 .. 10){
			die unless _ARRAY0($o);
		}
	},

	'array_ref' => sub{
		for(1 .. 10){
			die unless is_array_ref($o);
		}
	},
	'ref()' => sub{
		for(1 ..10){
			die unless ref($o) eq 'ARRAY';
		}
	},

};

$o = {};
print "\n\tfor a HASH reference\n";
cmpthese -1 => {
	'_ARRAY0' => sub{
		for(1 .. 10){
			die if _ARRAY0($o);
		}
	},

	'array_ref' => sub{
		for(1 .. 10){
			die if is_array_ref($o);
		}
	},
	'ref()' => sub{
		for(1 .. 10){
			die if ref($o) eq 'ARRAY';
		}
	},
};
