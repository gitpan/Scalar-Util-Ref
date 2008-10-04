#!perl -w

use strict;
use Test::More tests =>7;

use Scalar::Util::Ref qw(gen_sref);

my $sref = \do{ my $anon };

is_deeply gen_sref(), $sref, 'gen_sref';
is_deeply gen_sref(undef), $sref, 'gen_sref';

is_deeply gen_sref(10), \10;
is_deeply gen_sref('foo'), \'foo';

ok !Internals::SvREADONLY(${ gen_sref(10) }), 'not readonly';

my $foo;

# equivalent to "$foo = \do{ my $tmp = $foo }"
$foo = gen_sref $foo;

is_deeply $foo, $sref;

ok eval{ ${gen_sref()} = 10; }, 'writable';
