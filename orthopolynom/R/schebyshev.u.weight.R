schebyshev.u.weight <- function ( x )
{
###
###	This function returns the value of the weight function
###	for the shifted Chebyshev polynomial of the second kind, Uk( x )
###
###	Parameter
###	x = the function argument
###
	n <- length( x )
	y <- rep( 0, n )
	for ( i in 1:n ) {
		if ( ( x[i] > 0 ) && ( x[i] < 1 ) )
			y[i] <- sqrt( x[i] - x[i] * x[i] )
	}
	return( y )
}
