vmandelbrot <- function(av, b0, lim) {
  mandelbrot <- function(a0) {
    a <- a0; b <- b0
    a2 <- a * a
    b2 <- b * b
    n <- 0
    while (a2 + b2 < 4 && n < lim) {
      b <- 2 * a * b + b0
      a <- a2 - b2 + a0
      a2 <- a * a
      b2 <- b * b
      n <- n + 1
    }
    n
  }
  unlist(lapply(av, mandelbrot))
}

x <- seq(-2.0, 0.6, length.out=240)
y <- seq(-1.3, 1.3, length.out=240)
m <- 100

if (dev.cur() == 1) get(getOption("device"))()

library(nws)
s <- sleigh()
z <- matrix(m, length(x), length(y))
accum <- function(results, indices) {
  a <- do.call(cbind, results)
  z[, indices] <<- a
  image(x, y, z, col=c(rainbow(m), '#000000'))
}
opts <- list(accumulator=accum, chunkSize=10, loadFactor=4)
eachElem(s, vmandelbrot, list(b0=y), list(av=x, lim=m), eo=opts)
