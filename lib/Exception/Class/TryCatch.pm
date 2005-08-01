package Exception::Class::TryCatch;
use 5.005; # Aiming for same as Exception::Class
#use warnings -- not supported in Perl 5.5, darn
use strict;
use Exception::Class;

BEGIN {
    use Exporter ();
    use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = "1.08";
    @ISA         = qw (Exporter);
    @EXPORT      = qw ( catch try caught );
    @EXPORT_OK   = ();
    %EXPORT_TAGS = ();
}

my @error_stack;

##### main pod documentation #####

=head1 NAME

Exception::Class::TryCatch - Syntactic try/catch sugar for use with Exception::Class

=head1 SYNOPSIS

    use Exception::Class::TryCatch;
    
    # simple usage of catch()
    
    eval { Exception::Class::Base->throw('error') };
    catch my $err and warn $err->error;

    # catching only certain types or else rethrowing
    
    eval { Exception::Class::Base::SubClass->throw('error') };
    catch( my $err, ['Exception::Class::Base', 'Other::Exception'] )
        and warn $err->error; 
    
    # caught() is a synonym for catch()
    
    eval { Exception::Class::Base->throw('error') };
    if ( caught my $err ) {
        $err->isa('this') and do { handle_this($err) };
        $err->isa('that') and do { handle_that($err) };
    }
    
    # use "try eval" to push exceptions onto a stack to catch later
    
    try eval { 
        Exception::Class::Base->throw('error') 
    } and do {
        # cleanup that might use "try/catch" again
    };
    catch my $err;
  
=head1 DESCRIPTION

Exception::Class::TryCatch provides syntactic sugar for use with
L<Exception::Class> using the familiar keywords C<try> and C<catch>.  Its
primary objective is to allow users to avoid dealing directly with C<$@> by
ensuring that any exceptions caught in an C<eval> are captured as
L<Exception::Class> objects, whether they were thrown objects to begin with or
whether the error resulted from C<die>.  This means that users may immediately
use C<isa> and various L<Exception::Class> methods to process the exception. 

In addition, this module provides for a method to push errors onto a hidden
error stack immediately after an C<eval> so that cleanup code or other error
handling may also call C<eval> without the original error in C<$@> being lost.

Inspiration for this module is due in part to Dave Rolsky's
article "Exception Handling in Perl With Exception::Class" in
I<The Perl Journal> (Rolsky 2004).

The C<try/catch> syntax used in this module does not use code reference
prototypes the way the L<Error.pm|Error> module does, but simply provides some
helpful functionality when used in combination with C<eval>.  As a result, it
avoids the complexity and dangers involving nested closures and memory leaks
inherent in L<Error.pm|Error> (Perrin 2003).  

Rolsky (2004) notes that these memory leaks may not occur in recent versions of
Perl, but the approach used in Exception::Class::TryCatch should be safe for all
versions of Perl as it leaves all code execution to the C<eval> in the current
scope, avoiding closures altogether.

=head1 USAGE

=cut

#--------------------------------------------------------------------------#
# catch()/caught()
#--------------------------------------------------------------------------#

=head2 C<catch, caught>

    # zero argument form
    my $err = catch;

    # one argument forms
    catch my $err;
    my $err = catch( [ 'Exception::Type', 'Exception::Other::Type' ] );

    # two argument form
    catch my $err, [ 'Exception::Type', 'Exception::Other::Type' ];

Returns an C<Exception::Class::Base> object (or an object which is a 
subclass of it) if an exception has been caught by C<eval> or else 
returns C<undef> if no error exists.  The exception is either popped
from a hidden error stack (see C<try>) or, if the stack is empty, taken from
the current value of C<$@>.

If the exception is not an C<Exception::Class::Base> object (or subclass
object), an C<Exception::Class::Base> object will be created using the string
contents of the exception.  This means that calls to C<die> will be wrapped and
may be treated as exception objects.  Other objects caught will be stringfied
and wrapped likewise.  Such wrapping will likely result in confusing stack
traces and the like, so any methods other than C<error> used on 
C<Exception::Class::Base> objects caught should be used with caution.

C<catch> is prototyped to take up to two optional scalar arguments.  The single
argument form has two variations.  

=over

=item *

If the argument is a reference to an array,
any exception caught that is not of the same type (or a subtype) of one
of the classes listed in the array will be rethrown.  

=item *

If the argument is not a reference to an array, C<catch> 
will set the argument to the same value that is returned. 
This allows for the C<catch my $err> idiom without parentheses.

=back

In the two-argument form, the first argument is set to the same value as is
returned.  The second argument must be an array reference and is handled 
the same as as for the single argument version with an array reference, as
given above.

C<caught> is a synonym for C<catch> for syntactic convenience.

=cut

sub catch(;$$) {
    my $e;
    my $err = @error_stack ? pop @error_stack : $@;
    if ($err eq '') {
        $e = undef;
    }
    elsif ( UNIVERSAL::isa($err, 'Exception::Class::Base' ) ) {
        $e = $err;
    } 
    else {
        # use error message or hope something stringifies
        $e = Exception::Class::Base->new( "$err" );
    }
    unless ( ref($_[0]) eq 'ARRAY' ) { 
        $_[0] = $e;
        shift;
    }
    if ($e) {
        if ( defined($_[0]) and ref($_[0]) eq 'ARRAY' ) {
            $e->rethrow() unless grep { $e->isa($_) } @{$_[0]};
        }
    }
    return $e;
}

*caught = \&catch;

#--------------------------------------------------------------------------#
# try()
#--------------------------------------------------------------------------#

=head2 C<try>

    try eval {
      #dangerous code
    };
    catch my $err;
 
    $rv = try eval { return $scalar };
    @rv = try [ eval { return @array } ];
    
Pushes the current error (C<$@>) onto a hidden error stack for later use by
C<catch>.  C<try> uses a prototype that expects a single scalar so that it can
be used with eval without parentheses.  As C<eval { BLOCK }> is an argument
to try, it will be evaluated just prior to C<try>, ensuring that C<try>
captures the correct error status.  C<try> does not itself handle any errors --
it merely records the results of C<eval>. C<try { BLOCK }> will be interpreted
as passing a hash reference and will (probably) not compile. (And if it does,
it will result in very unexpected behavior.)

Since C<try> requires a single argument, C<eval> will normally be called
in scalar context.  To use C<eval> in list context with C<try>, put the 
call to C<eval> in an anonymous array:  

  @rv = try [ eval {return @array} ];

When C<try> is called in list context, if the argument to C<try> is an array
reference, C<try> will dereference the array and return the resulting list,
In scalar context, of course, C<try> passes through the scalar value returned
by C<eval> -- even if that is an array reference -- without modifications.

When using C<try> in a compound idioms like the following, be sure that
the C<eval> returns a true value:

    try eval {
     # code
     1;
    } and do {
     # cleanup
    };
    catch my $err;
 
C<try> must always be properly bracketed with a matching C<catch> or unexpected
behavior may result when C<catch> pops the error off of the stack.  C<try> 
executes right after its C<eval>, so inconsistent usage of C<try> like the
following will work as expected:

    try eval {
        eval { die "inner" };
        catch my $inner_err
        die "outer" if $inner_err;
    };
    catch my $outer_err;
    # handle $outer_err;
    
However, the following code is a problem:

    # BAD EXAMPLE
    try eval {
        try eval { die "inner" };
        die $@ if $@;
    };
    catch my $outer_err;
    # handle $outer_err;
    
This code will appear to run correctly, but C<catch> gets the exception
from the inner C<try>, not the outer one, and there will still be an exception
on the error stack which will be caught by the next C<catch> in the program, 
causing unexpected (and likely hard to track) behavior.

In short, if you use C<try>, you must C<catch>.  The problem code above should
be rewritten as:

    try eval {
        try eval { die "inner" };
        catch my $inner_err;
        $inner_err->rethrow if $inner_err;
    };
    catch my $outer_err;
    # handle $outer_err;

=cut

sub try($) {
    my $v = shift;
    push @error_stack, $@;
    return ref($v) eq 'ARRAY' ? @$v : $v if wantarray;
    return $v;
}


1; #this line is important and will help the module return a true value
__END__

=head1 REFERENCES

=over

=item 1. 

perrin. (2003), "Re: Re2: Learning how to use the Error module by example",
(perlmonks.org), Available: http://www.perlmonks.org/index.pl?node_id=278900
(Accessed September 8, 2004).

=item 2.

Rolsky, D. (2004), "Exception Handling in Perl with Exception::Class",
I<The Perl Journal>, vol. 8, no. 7, pp. 9-13

=back

=head1 SEE ALSO

- L<Exception::Class>

- L<Test::Exception>

- L<Error> [but see (Perrin 2003) before using]

=head1 INSTALLATION

To install this module, type the following:

   perl Build.PL
   ./Build
   ./Build test
   ./Build install

=head1 BUGS

Though this is a simple module, it may contain bugs or have unexpected
behaviors.

Please report bugs using the CPAN Request Tracker at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Exception-Class-TryCatch

=head1 AUTHOR

David A Golden <dagolden@cpan.org>

http://dagolden.com/

=head1 COPYRIGHT

Copyright (c) 2004, 2005 by David A. Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
