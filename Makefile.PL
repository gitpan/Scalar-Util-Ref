use 5.008_001;
use strict;
use warnings;
use inc::Module::Install;

name 'Scalar-Util-Ref';

all_from 'lib/Scalar/Util/Ref.pm';

requires 'XSLoader'   => 0.06;

test_requires 'Test::More' => 0.62;


WriteMakefile(
	OBJECT => '$(O_FILES)',
	clean => {
		FILES => 'Scalar-Util-Ref-* *.stackdump *.gcov *.gcda *.gcno'
	},
);
