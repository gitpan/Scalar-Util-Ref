package Scalar::Util::Ref;

use 5.008_001;
use strict;

our $VERSION = '0.01';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
	is_scalar_ref is_array_ref is_hash_ref is_code_ref is_glob_ref is_regex_ref
	is_instance

	scalar_ref array_ref hash_ref code_ref glob_ref regex_ref
	instance

	gen_sref
);
our %EXPORT_TAGS = (
	all => \@EXPORT_OK,

	check   => [qw(
		is_scalar_ref is_array_ref is_hash_ref is_code_ref
		is_glob_ref is_regex_ref is_instance
	)],
	assert  => [qw(
		scalar_ref array_ref hash_ref code_ref
		glob_ref regex_ref instance
	)],
);


1;
__END__

=head1 NAME

Scalar::Util::Ref - A selection of general-utility reference subroutines

=head1 VERSION

This document describes Scalar::Util::Ref version 0.01

=head1 SYNOPSIS

	use Scalar::Util::Ref qw(:assert);

	sub foo{
		my $sref = scalar_ref(shift);
		my $aref = array_ref(shift);
		my $href = hash_ref(shift);
		my $cref = code_ref(shift);
		my $gref = glob_ref(shift);
		my $rref = regex_ref(shift);
		my $obj  = instance(shift, 'Foo');
		# ...
	}

	use Scalar::Util::Ref qw(:check);

	sub bar{
		my $x = shift;
		if(is_scalar_ref $x){
			# $x is an array reference
		}
		# ...
		elsif(is_instance $x, 'Foo'){
			# $x is an instance of Foo
		}
		# ...
	}

	# to generate a scalar reference
	use Scalar::Util:Ref qw(gen_sref)

	my $ref_to_undef = gen_sref();

	$x = gen_sref($x); # OK

	sub baz{
		my $x = shift;

		use instanceof; # introduces 'instanceof' operator

		if($x << 'Foo'){
			# $x is an instance of Foo
		}
	}

=head1 DESCRIPTION

This module provides general utilities for references and object references.

=head1 INTERFACE

=head2 Check functions

Check functions are introduced by the C<:check> tag, which check the argument
type.

=over 4

=item is_scalar_ref($x)

For a SCALAR reference.

=item is_array_ref($x)

For an ARRAY reference.

=item is_hash_ref($x)

For a HASH reference.

=item is_code_ref($x)

For a CODE reference.

=item is_glob_ref($x)

For a GLOB reference.

=item is_regex_ref($x)

For a regular expression reference.

=item is_instance($x, $class)

For an instance of a class.

It is equivalent to something like
C<Scalar::Util::blessed($x) && $x->isa($class) ? $x : undef>,
but significantly faster and easy to use.

=back

=head2 Assert functions

Assert functions are introduced by the C<:assert> tag, and returns the
first argument C<$x>.
They are like the C<:check> functions, but they will die if the argument type
is not the wanted type.

=over 4


=item scalar_ref($x)

For a SCALAR reference.

=item array_ref($x)

For an ARRAY reference.

=item hash_ref($x)

For a HASH reference.

=item code_ref($x)

For a CODE reference.

=item glob_ref($x)

For a GLOB reference.

=item regex_ref($x)

For a regular expression reference.

=item instance($x, $class)

For an instance of a class.

=back

=head2 Scalar reference generator

=over 4

=item gen_sref()

Generates anonymous scalar reference to C<undef>.

=item gen_sref(expr)

Generates anonymous scalar reference to I<expr>.

=back

=head1 DEPENDENCIES

Perl 5.8.1 or later, and a C compiler.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-scalar-util-ref@rt.cpan.org/>, or through the web interface at
L<http://rt.cpan.org/>.

=head1 SEE ALSO

L<instanceof>.

L<Params::Util>.

L<Scalar::Util>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
