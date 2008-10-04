#!perl -w
use strict;


use Test::More tests => 23;


BEGIN{
	package Foo;
	sub new{ bless {}, shift }
	package Bar;
	our @ISA = qw(Foo);
	package Baz;
	sub new{ bless {}, shift }
	sub isa{
		my($x, $y) = @_;
		return $y eq 'Foo';
	}

	package Broken;
	sub isa; # pre-declaration only

	package AL;
	sub new{ bless {}, shift }
	sub DESTROY{}
	sub isa;

	sub AUTOLOAD{
		#our $AUTOLOAD; ::diag "$AUTOLOAD(@_)";
		1;
	}
}

{
	use instanceof;



	ok +(Foo->new << 'Foo'), 'instanceof';
	ok !(Foo->new << 'Bar');
	ok  (Bar->new << 'Foo');
	ok  (Bar->new << 'Bar');

	ok  (Baz->new << 'Foo');
	ok !(Baz->new << 'Bar');
	ok !(Baz->new << 'Baz');

	ok !(undef() << 'Foo');
	ok !(1     << 'Foo'); # not left shift
	ok !('Foo' << 'Foo');
	ok !({}    << 'Foo');

	ok !({} << 'HASH');
	ok !([] << 'ARRAY');

	ok !eval{ not( Broken->new() << 'Broken') };

	ok (AL->new << 'AL');
	ok (AL->new << 'Foo');

	ok qr/foo/ << 'Regexp';

	my $universal_isa = UNIVERSAL->can('isa');
	undef *UNIVERSAL::isa;

	ok !(Bar->new << 'Foo'), 'UNIVERSAL::isa deleted';

	*UNIVERSAL::isa = $universal_isa;
}

{
	use warnings FATAL => 'numeric';

	ok !eval{ my $x = Foo->new << 'Foo'; 1 }, 'instanceof not enabled';

	use instanceof;

	ok eval{ Foo->new << 'Foo' }, 'instanceof enabled';

	is 1 << 1, 2, 'left shift';
	is 1 << 2, 4;

	no instanceof;

	ok !eval{ Foo->new << 'Foo';  }, 'instanceof disabled';

}