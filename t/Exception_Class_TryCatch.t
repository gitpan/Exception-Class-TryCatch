#!/usr/bin/perl
use strict;
use warnings;
use blib;  

# Exception::Class::TryCatch  

use Test::More tests =>  33 ;
use Test::Exception;

BEGIN { 
    use_ok( 'Exception::Class::TryCatch' );
    use_ok( 'Exception::Class', 'My::Exception::Class' );
}

my $e;

#--------------------------------------------------------------------------#
# Test basic catching of Exception::Class thrown errors
#--------------------------------------------------------------------------#

eval { My::Exception::Class->throw('error1') };
$e = catch;
ok ( $e, "Caught My::Exception::Class error1" );
isa_ok ( $e, 'Exception::Class::Base' );
isa_ok ( $e, 'My::Exception::Class' );
is ( $e->error, 'error1', "Exception is 'error1'" );

eval { My::Exception::Class->throw('error2'); };
$e = catch;
ok ( $e, "Caught My::Exception::Class error2" );
isa_ok ( $e, 'My::Exception::Class' );
is ( $e->error, 'error2', "Exception is 'error2'" );

#--------------------------------------------------------------------------#
# Test handling of normal die (not Exception::Class throw() )
#--------------------------------------------------------------------------#

eval { die "error3" };
$e = catch;
ok ( $e, "Caught 'die error3'" );
isa_ok ( $e, 'Exception::Class::Base' );
like ( $e->error, qr/^error3 at/, "Exception is 'error3 at...'" );

eval { die 0 };
$e = catch;
ok ( $e, "Caught 'die 0'" );
isa_ok ( $e, 'Exception::Class::Base' );
like ( $e->error, qr/^0 at/, "Exception is '0 at...'" );

eval { die };
$e = catch;
ok ( $e, "Caught 'die'" );
isa_ok ( $e, 'Exception::Class::Base' );
like ( $e->error, qr/^Died at/, "Exception is 'Died at...'" );

#--------------------------------------------------------------------------#
# Test handling of non-dying evals
#--------------------------------------------------------------------------#

eval { 1 };
$e = catch;
is ($e, undef, "Didn't catch eval of 1" );

eval { 0 };
$e = catch;
is ($e, undef, "Didn't catch eval of 0" );

#--------------------------------------------------------------------------#
# Test catch (my e) syntax-- pass by reference
#--------------------------------------------------------------------------#

eval { My::Exception::Class->throw('error'); };
catch my $err;
is ( $err->error, 'error', "catch X syntax worked" );

#--------------------------------------------------------------------------#
# Test caught synonym
#--------------------------------------------------------------------------#
 
undef $err;
eval { My::Exception::Class->throw( "error" ) };
caught $err;
is ( $err->error, 'error', "caught synonym worked" );

#--------------------------------------------------------------------------#
# Test catch setting error variable to undef if no error
#--------------------------------------------------------------------------#

eval { My::Exception::Class->throw( "error" ) };
catch $err;
eval { 1 };
catch $err;
is ( $err, undef, "catch undefs a passed error variable if no error" );

#--------------------------------------------------------------------------#
# Test simple try/catch
#--------------------------------------------------------------------------#

my $rv = try eval { My::Exception::Class->throw( "error" ) };
catch $err;
ok ( $rv, "try returns true" );
is ( $err->error, 'error', "simple try/catch works" );

#--------------------------------------------------------------------------#
# Test multiple try/catch with double error
#--------------------------------------------------------------------------#

my $inner_err;
my $outer_err;

for my $out ( 0, 1 ) {
	for my $in (0, 1 ) {
		try eval { $out ? My::Exception::Class->throw( "outer" ) : 1 };
		try eval { $in ? My::Exception::Class->throw( "inner" ) : 1};
		catch $inner_err;
		catch $outer_err;
		if ($in) {
			is ( $inner_err->error, "inner", 
				"Inner try caught correctly in case ($out,$in)" );
		}
		else {
			is ( $inner_err, undef,
				"Inner try caught correctly in case ($out,$in)" );
		}
		if ($out) {
			is ( $outer_err->error, "outer", 
				"Outer try caught correctly in case ($out,$in)" );
		}
		else {
			is ( $outer_err, undef,
				"Outer try caught correctly in case ($out,$in)" );
		}
	}
}

