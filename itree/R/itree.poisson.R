#ALG: itree copies this direclty from rpart.

itree.poisson <- function(y, offset, parms, wt)
{
    if (is.matrix(y)) {
	if (ncol(y) != 2L)
            stop("response must be a 2 column matrix or a vector")
	if (!is.null(offset)) y[, 1L] <- y[, 1L] * exp(offset)
    } else {
	if (is.null(offset)) y <- cbind(1, y)
	else  y <- cbind( exp(offset), y)
    }
    if (any(y[, 1L] <= 0)) stop("Observation time must be > 0")
    if (any(y[, 2L] < 0))  stop("Number of events must be >= 0")

    if (missing(parms)) parms <- c(shrink = 1L, method = 1L)
    else {
	parms <- as.list(parms)
	if(is.null(names(parms))) stop("You must input a named list for parms")
	parmsNames <- c("method", "shrink")
	indx <- pmatch(names(parms), parmsNames, nomatch = 0L)
	if (any(indx == 0L))
            stop("'parms' component not matched: ", names(parms)[indx == 0L])
	else names(parms) <- parmsNames[indx]

	if (is.null(parms$method)) method <- 1L
	else method <- pmatch(parms$method, c("deviance", "sqrt"))
	if (is.null(method)) stop("Invalid error method for Poisson")

	if (is.null(parms$shrink)) shrink <- 2L - method
	else shrink <- parms$shrink

	if (!is.numeric(shrink) || shrink < 0L)
            stop("Invalid shrinkage value")
	parms <- c(shrink = shrink, method = method)
    }

    list(y = y, parms = parms, numresp = 2L, numy = 2L,
	 summary = function(yval, dev, wt, ylevel, digits) {
	     paste("  events=", formatg(yval[, 2L]),
                   ",  estimated rate=" , formatg(yval[, 1L], digits),
                   " , mean deviance=", formatg(dev/wt, digits),
                   sep = "")
         },
	 text = function(yval, dev, wt, ylevel, digits, n, use.n) {
	     if(use.n) paste(formatg(yval[, 1L], digits), "\n",
                              formatg(yval[, 2L]), "/", n, sep = "")
             else paste(formatg(yval[, 1L], digits))
         })
}
