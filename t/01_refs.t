#!perl -w
use strict;

use Test::More tests => 42;

use Scalar::Util::Ref qw(:all);
use Symbol qw(gensym);

sub lval_f :lvalue{
	my $f;
}


ok is_scalar_ref(\''), 'is_scalar_ref';
ok is_scalar_ref(\lval_f()), 'is_scalar_ref (lvalue)';
ok is_scalar_ref(\\''), 'is_scalar_ref (ref)';
ok!is_scalar_ref(bless \do{my$o}), 'is_scalar_ref';
ok!is_scalar_ref({}), 'is_scalar_ref';
ok!is_scalar_ref(undef), 'is_scalar_ref';
ok!is_scalar_ref(*STDOUT{IO}), 'is_scalar_ref';

ok is_array_ref([]), 'is_array_ref';
ok!is_array_ref(bless []), 'is_array_ref';
ok!is_array_ref({}), 'is_array_ref';
ok!is_array_ref(undef), 'is_array_ref';

ok is_hash_ref({}), 'is_hash_ref';
ok!is_hash_ref(bless {}), 'is_hash_ref';
ok!is_hash_ref([]), 'is_hash_ref';
ok!is_hash_ref(undef), 'is_hash_ref';

ok is_code_ref(sub{}), 'is_code_ref';
ok!is_code_ref(bless sub{}), 'is_code_ref';
ok!is_code_ref({}), 'is_code_ref';
ok!is_code_ref(undef), 'is_code_ref';

ok is_glob_ref(gensym()), 'is_glob_ref';
ok!is_glob_ref(bless gensym()), 'is_glob_ref';
ok!is_glob_ref({}), 'is_glob_ref';
ok!is_glob_ref(undef), 'is_glob_ref';

ok is_regex_ref(qr/foo/), 'is_regex_ref';
ok!is_regex_ref({}), 'is_regex_ref';
ok!is_regex_ref(bless [], 'Regexp'), 'fake regexp';


ok scalar_ref(\''), 'scalar_ref';
ok !eval{ scalar_ref([]); 1 }, 'scalar_ref';
ok !eval{ scalar_ref(undef); 1}, 'scalar_ref';
ok !eval{ scalar_ref(1); 1 }, 'scalar_ref';

ok array_ref([]), 'array_ref';
ok !eval{ array_ref({}); 1 }, 'array_ref';

ok hash_ref({}), 'hash_ref';
ok !eval{ hash_ref([]); 1 }, 'hash_ref';

ok code_ref(sub{}), 'code_ref';
ok !eval{ code_ref([]); 1 }, 'code_ref';

ok glob_ref(gensym()), 'glob_ref';
ok !eval{ glob_ref([]); 1 }, 'glob_ref';


ok regex_ref(qr/foo/), 'regex_ref';
ok !eval{ regex_ref([]); 1 }, 'regex_ref';

ok !eval{ is_scalar_ref(); 1 }, 'not enough argument';
ok !eval{ scalar_ref(); 1},        'not enough argument';
