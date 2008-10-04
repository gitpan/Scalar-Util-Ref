package instanceof;

use strict;

use Scalar::Util::Ref (); # load XS

sub import{
	$^H |= 0x00020000; # HINT_LOCALIZE_HH
	$^H{(__PACKAGE__)} = _enter();
	return;
}
sub unimport{
	delete $^H{(__PACKAGE__)};
	return;
}

1;

__END__

=head1 NAME

instanceof - Generic overloading of "<<" as "instanceof" operator

=head1 SYNOPSIS

	use instanceof;

	if($x << $class){
		# $x is an instance of $class
	}
	
	no instanceof;

=head1

This pragmatic module provides an B<instanceof> operator, which is
equivalent to C<Scalar::Util::Ref::is_instance()> but even faster than
it.

The operator is introduced by the C<use instanceof> directive with lexical
scope, and disabled by the C<no instanceof> directive.

=head1 SEE ALSO

L<Scalar::Util::Ref>.

=head1 AUTHOR

Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Goro Fuji E<lt>gfuji(at)cpan.orgE<gt>. Some rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

