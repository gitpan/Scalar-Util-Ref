#!perl -w

use strict;
use Benchmark qw(:all);
use Scalar::Util::Ref qw(gen_sref);

timethese -1 => {
	gen_sref => sub{
		for(1 .. 10){
			my $ref = gen_sref();
		}
	},
	'\do{my $tmp}' => sub{
		for(1 .. 10){
			my $ref = \do{ my $tmp };
		}
	},
};

