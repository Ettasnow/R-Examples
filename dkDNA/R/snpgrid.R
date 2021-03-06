snpgrid2 <-
function(nsnp, x, y, theta){
  stopifnot(nargs() == 4, nsnp > 0, length(x) == length(y))
  
  out <- .Fortran("snpgrid", n=as.integer(nsnp), x=as.integer(x), y=as.integer(y), theta=as.double(theta), k =  double(1))
  return(out[["k"]])
}


snpgrid <-
function(X, theta){
  stopifnot(nargs() == 2)
  
  nid <- nrow(X)
  nsnp <- ncol(X)
  DK <- matrix(0, ncol=nid, nrow=nid)
  
  for (i in 1:(nid-1)){
    DK[i,i] <- snpgrid2(nsnp, X[i,], X[i,], theta)
    for (j in (i+1):nid){
      xy <- snpgrid2(nsnp, X[i,], X[j,], theta)
      DK[i,j] <- DK[j,i] <- xy
    }
  }
  DK[nid, nid] <- snpgrid2(nsnp, X[nid,], X[nid,], theta)

  return(DK)
  
}
