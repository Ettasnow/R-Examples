create.exponential.basis <- function (rangeval=c(0,1), nbasis=NULL,
                         ratevec=NULL, dropind=NULL, quadvals=NULL,
                         values=NULL, basisvalues=NULL, names='exp',
                         axes=NULL)
{

#  This function creates an exponential functional data basis
#  Arguments
#  RANGEVAL ... An array of length 2 containing the lower and upper
#               boundaries for the rangeval of argument values
#  NBASIS   ... The number of basis functions.  If this conflicts with
#               the length of RATEVEC, the latter is used.
#  RATEVEC  ... The rate parameters defining exp(ratevec[i]*x)
#  DROPIND  ... A vector of integers specifying the basis functions to
#               be dropped, if any.
#  QUADVALS .. A NQUAD by 2 matrix.  The firs t column contains quadrature
#                points to be used in a fixed point quadrature.  The second
#                contains quadrature weights.  For example, for (Simpson"s
#                rule for (NQUAD = 7, the points are equally spaced and the
#                weights are delta.*[1, 4, 2, 4, 2, 4, 1]/3.  DELTA is the
#                spacing between quadrature points.  The default is
#                matrix("numeric",0,0).
#  VALUES  ... A list, with entries containing the values of
#                the basis function derivatives starting with 0 and
#                going up to the highest derivative needed.  The values
#                correspond to quadrature points in QUADVALS and it is
#                up to the user to decide whether or not to multiply
#                the derivative values by the square roots of the
#                quadrature weights so as to make numerical integration
#                a simple matrix multiplication.
#                Values are checked against QUADVALS to ensure the correct
#                number of rows, and against NBASIS to ensure the correct
#                number of columns.
#                The default value of is VALUES is vector("list",0).
#                VALUES contains values of basis functions and derivatives at
#                quadrature points weighted by square root of quadrature weights.
#                These values are only generated as required, and only if slot
#                QUADVALS is not matrix("numeric",0,0).
#  BASISVALUES ... A vector of lists, allocated by code such as
#                vector("list",1).
#                This field is designed to avoid evaluation of a
#                basis system repeatedly at a set of argument values.
#                Each list within the vector corresponds to a specific set
#                of argument values, and must have at least two components,
#                which may be tagged as you wish.
#                The first component in an element of the list vector contains the
#                argument values.
#                The second component in an element of the list vector
#                contains a matrix of values of the basis functions evaluated
#                at the arguments in the first component.
#                The third and subsequent components, if present, contain
#                matrices of values their derivatives up to a maximum
#                derivative order.
#                Whenever function getbasismatrix is called, it checks
#                the first list in each row to see, first, if the number of
#                argument values corresponds to the size of the first dimension,
#                and if this test succeeds, checks that all of the argument
#                values match.  This takes time, of course, but is much
#                faster than re-evaluation of the basis system.  Even this
#                time can be avoided by direct retrieval of the desired
#                array.
#                For example, you might set up a vector of argument values
#                called "evalargs" along with a matrix of basis function
#                values for these argument values called "basismat".
#                You might want too use tags like "args" and "values",
#                respectively for these.  You would then assign them
#                to BASISVALUES with code such as
#                  basisobj$basisvalues <- vector("list",1)
#                  basisobj$basisvalues[[1]] <-
#                               list(args=evalargs, values=basismat)
#  Returns
#  BASISOBJ  ... a functional data basis object of type "expon"

#  Last modified 9 November 2008 by Spencer Graves
#  Last modified 6 January 2008 by Jim Ramsay

#  Default basis for missing arguments
##
## 1.  Check RANGEVAL
##
  if(!is.numeric(rangeval))
    stop('rangaval must be numeric;  class(rangeval) = ',
         class(rangeval) )
  if(length(rangeval)<1)
    stop('rangeval must be a numeric vector of length 2;  ',
         'length(rangeval) = 0.')
  if (length(rangeval) == 1) {
    if( rangeval <= 0)
      stop("rangeval a single value that is not positive:  ",
           rangeval)
    rangeval <- c(0,rangeval)
  }
  if(length(rangeval)>2)
    stop('rangeval must be a vector of length 2;  ',
         'length(rangeval) = ', length(rangeval))
  if(diff(rangeval)<=0)
    stop('rangeval must cover a positive range;  diff(rangeval) = ',
         diff(rangeval) )
##
## 2.  check nbasis and ratevec
##
  {
    if(is.null(nbasis)){
      if(is.null(ratevec)){
        nbasis <- 2
        ratevec <- 0:1
      }
      else {
        nbasis <- length(ratevec)
        if(nbasis<1)
          stop('ratevec must have positive length;  length(ratevec) = 0')
        if(!is.numeric(ratevec))
          stop('ratevec must be numeric;  class(ratevec) = ',
               class(ratevec) )
        if(length(unique(ratevec)) != nbasis)
          stop('ratevec contains duplicates;  not allowed.')
      }
    }
    else {
      if(is.null(ratevec))
        ratevec <- 0:(nbasis-1)
      else{
        if(length(ratevec) != nbasis)
          stop('length(ratevec) must equal nbasis;  length(ratevec) = ',
               length(ratevec), ' != ', 'nbasis = ', nbasis)
        if(length(unique(ratevec)) != nbasis)
          stop('ratevec contains duplicates;  not allowed.')
      }
    }
  }
##
## 3.  check DROPIND
##
  if (length(dropind) > 0){
    if(!is.numeric(dropind))
      stop('dropind must be numeric;  is ', class(dropind))
    doops <- which((dropind%%1)>0)
    if(length(doops)>0)
      stop('dropind must be integer;  element ', doops[1],
           " = ", dropind[doops[1]], '; fractional part = ',
           dropind[doops[1]] %%1)
#
    doops0 <- which(dropind<=0)
    if(length(doops0)>0)
      stop('dropind must be positive integers;  element ',
           doops0[1], ' = ', dropind[doops0[1]], ' is not.')
    doops2 <- which(dropind>nbasis)
    if(length(doops2)>0)
        stop("dropind must not exceed nbasis = ", nbasis,
             ';  dropind[', doops2[1], '] = ', dropind[doops2[1]])
#
    dropind <- sort(dropind)
    if(length(dropind) > 1) {
      if(min(diff(dropind)) == 0)
        stop("Multiple index values in DROPIND.")
    }
  }
##
## 4.  set up the basis object
##
  type        <- "expon"
  params      <- as.vector(ratevec)

  basisobj <- basisfd(type=type,     rangeval=rangeval, nbasis=nbasis,
                    params=params, dropind=dropind,   quadvals=quadvals,
                    values=values, basisvalues=basisvalues)
##
## 5.  names
##
  {
    if(length(names) == nbasis)
      basisobj$names <- names
    else {
      if(length(names)>1)
        stop('length(names) = ', length(names), ';  must be either ',
             '1 or nbasis = ', nbasis)
      basisobj$names <- paste(names, 0:(nbasis-1), sep="")
    }
  }
##
## 6.  Done
##
  if(!is.null(axes))basisobj$axes <- axes

  basisobj

}
