## ------------------------------------------------------------------------
require(FunChisq)
x1=matrix(c(5,1,5,1,5,1,1,0,1), nrow=3)
x1
fun.chisq.test(x1)

## ------------------------------------------------------------------------
x2=matrix(c(5,1,1,1,5,0,5,1,1), nrow=3)
x2
fun.chisq.test(x2)

## ------------------------------------------------------------------------
x3=matrix(c(5,1,1,1,5,0,9,1,1), nrow=3)
x3
fun.chisq.test(x3)

## ------------------------------------------------------------------------
x4=x1*sum(x3)/sum(x1)
x4
fun.chisq.test(x4)

