#!perl -w

use strict;
use Benchmark qw(:all);

use Scalar::Util::Ref qw(is_instance);

#use Scalar::Util qw(blessed);
#print 'Scalar::Util::blessed is ',
#	(defined(&Scalar::Util::dualvar) ? 'XS' : 'Pure Perl'),
#	' version', "\n";

BEGIN{
	package Base;
	sub new{
		bless {} => shift;
	}
	
	package Foo;
	our @ISA = qw(Base);
	package Foo::X;
	our @ISA = qw(Foo);
	package Foo::X::X;
	our @ISA = qw(Foo::X);
	package Foo::X::X::X;
	our @ISA = qw(Foo::X::X);

	package Unrelated;
	our @ISA = qw(Base);

	package SpecificIsa;
	our @ISA = qw(Base);
	sub isa{
		$_[1] eq 'Foo';
	}
}

foreach my $x (Foo->new, Foo::X::X::X->new, Unrelated->new, undef, {}){
	print 'For ';
	if(defined $x){
		if(ref $x){
			print $x;
		}
		else{
			print qq{"$x"};
		}
	}
	else{
		print 'undef';
	}
	print "\n";

	my $i = 0;

	cmpthese -1 => {

		'ref&eval{}' => sub{
			for(1 .. 10){
				$i++ if ref($x) && eval{ $x->isa('Foo') };
			}
		},
#		'scalar_util' => sub{
#			for(1 .. 10){
#				$i++ if blessed($x) && $x->isa('Foo');
#			}
#		},
		'instance()' => sub{
			for(1 .. 10){
				$i++ if is_instance($x, 'Foo');
			}
		},
		'instanceof' => sub{
			use instanceof;
			for(1 .. 10){
				$i++ if $x << 'Foo';
			}
		},
	};

	print "\n";
}
