test.new.fp <- function()
{
  fp <- new("fingerprint", bits=c(1,2,3,4), nbit=8, provider='rg',name='foo')
  checkTrue(!is.null(fp))
}

test.distance1 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(5,6,7,8), nbit=8)
  d <- distance(fp1,fp2)
  checkEquals(d, 0)
}

test.distance2 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  d <- distance(fp1,fp2)
  checkEquals(d, 1)
}

test.and1 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fpnew <- fp1 & fp2
  bits <- fpnew@bits
  checkTrue( all(bits == c(1,2,3,4)))
}
test.and2 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(5,6,7,8), nbit=8)
  fpnew <- fp1 & fp2
  bits <- fpnew@bits
  checkEquals(length(bits),0)
}

test.or1 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(5,6,7,8), nbit=8)
  fpnew <- fp1 | fp2
  bits <- fpnew@bits
  checkTrue(all(bits == c(1,2,3,4,5,6,7,8)))
}
test.or2 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fpnew <- fp1 | fp2
  bits <- fpnew@bits
  checkTrue(all(bits == c(1,2,3,4)))
}

test.not <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  nfp1 <- !fp1
  checkTrue(all(nfp1@bits == c(5,6,7,8)))
  checkTrue(all(fp1@bits == (!nfp1)@bits))
}

test.xor1 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fpnew <- xor(fp1,fp2)
  bits <- fpnew@bits
  checkEquals(length(bits),0)
}
test.xor2 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint",
             bits=c(5,6,7,8), nbit=8)
  fpnew <- xor(fp1,fp2)
  bits <- fpnew@bits
  checkEquals(length(bits),8)
  checkTrue(all(bits == c(1,2,3,4,5,6,7,8)))
}

test.fold1 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4), nbit=8)
  nfp <- fold(fp1)
  checkTrue(all(nfp@bits == c(1,2,3,4)))
}

test.fold2 <- function() {
  fp1 <- new("fingerprint",
             bits=c(1,2,3,4,8), nbit=8)
  nfp <- fold(fp1)
  checkTrue(all(nfp@bits == c(1,2,3,4)))
}

test.fp.to.matrix <- function() {
    fp1 <- new("fingerprint", bits=c(1,2,3,4), nbit=8)
    fp2 <- new("fingerprint", bits=c(5,6,7,8), nbit=8)
    fp3 <- new("fingerprint", bits=c(1,2,3,5,6,7,8), nbit=8)
    m1 <- fp.to.matrix(list(fp1,fp2,fp3))
    m2 <- rbind(c(1,1,1,1,0,0,0,0),
                c(0,0,0,0,1,1,1,1),
                c(1,1,1,0,1,1,1,1))
    checkTrue(all(m1 == m2))
}

test.tversky.1 <- function() {
  fp1 <- new("fingerprint", bits=c(1,2,3,4), nbit=8)
  fp2 <- new("fingerprint", bits=c(1,2,3,4), nbit=8)
  s <- distance(fp1, fp2, "tversky", a=1,b=1)
  checkEquals(1.0, s)
}
test.tversky.2 <- function() {
  fp1 <- new("fingerprint", bits=c(5,6,7,8), nbit=8)
  fp2 <- new("fingerprint", bits=c(1,2,3,4), nbit=8)
  s <- distance(fp1, fp2, "tversky", a=1,b=1)
  checkEquals(0.0, s)
}
test.tversky.3 <- function() {
  fp1 <- new("fingerprint", bits=c(4,6,7,8), nbit=8)
  fp2 <- new("fingerprint", bits=c(1,2,3,4), nbit=8)
  stv <- distance(fp1, fp2, "tversky", a=1,b=1)
  sta <- distance(fp1, fp2)  
  checkEquals(stv, sta)
}
test.tversky.4 <- function() {
  fp1 <- new("fingerprint", bits=c(4,6,7,8), nbit=8)
  fp2 <- new("fingerprint", bits=c(1,2,3,4), nbit=8)
  stv <- distance(fp1, fp2, "tversky", a=0.5,b=0.5)
  std <- distance(fp1, fp2, "dice")  
  checkEquals(stv, std)
}

test.fp.sim.matrix <- function() {
    fp1 <- new("fingerprint", bits=c(1,2,3,4), nbit=8)
    fp2 <- new("fingerprint", bits=c(5,6,7,8), nbit=8)
    fp3 <- new("fingerprint", bits=c(1,2,3,5,6,7,8), nbit=8)
    fpl <- list(fp1,fp2,fp3)
    sm <- round(fp.sim.matrix(fpl),2)
    am <- rbind(c(1,0,0.38),
                c(0,1,0.57),
                c(0.38,0.57,1))
    checkTrue(all(sm == am))
}

test.fp.balance <- function() {
  fp1 <- new("fingerprint", bits=c(1,2,3), nbit=6)  
  fp2 <- balance(fp1)
  checkTrue(12 == length(fp2))
  checkEquals(c(1,2,3,10,11,12), fp2@bits)
}

test.fps.reader <- function() {
  data.file <- file.path(system.file("unitTests", "bits.fps", package="fingerprint"))
  fps <- fp.read(data.file, lf=fps.lf)
  checkEquals(323, length(fps))

  ## OK, we need to pull in the bit positions Andrew specified
  for (i in seq_along(fps)) {
    expected <- sort(as.numeric(strsplit(fps[[i]]@misc[[1]],",")[[1]])+1)
    observed <- sort(fps[[i]]@bits)
    checkEquals(expected, observed, msg = sprintf("%s had a mismatch in bit positions", fps[[i]]@name))
  }
}

#######################################
##
## Feature vector tests
##
#######################################
test.feature <- function() {
  f1 <- new('feature', feature='F1')
  checkEquals(1, f1@count)

  f2 <- new('feature', feature='F2', count=as.integer(12))
  checkEquals(12, f2@count)
}

test.feature.c <- function() {
  f1 <- new('feature', feature='F1', count=as.integer(2))
  f2 <- new('feature', feature='F2', count=as.integer(3))
  fl <- c(f1, f2)
  checkEquals(2, length(fl))
  checkEquals("list", class(fl))
  checkTrue(identical(f1, fl[[1]]))
  checkTrue(identical(f2, fl[[2]]))  
}

test.feature.fp <- function() {
  feats <- sapply(letters[1:10], function(x) new('feature', feature=x, count=as.integer(1)))
  fv <- new('featvec', features=feats)
  checkEquals(10, length(fv))
}

test.feature.dist1 <- function() {
  f1 <- sapply(letters[1:10], function(x) new('feature', feature=x, count=as.integer(1)))
  f2 <- sapply(letters[1:10], function(x) new('feature', feature=x, count=as.integer(1)))
  fv1 <- new('featvec', features=f1)
  fv2 <- new('featvec', features=f2)
  d <- distance(fv1, fv2, method='tanimoto')
  checkEquals(1, d)
}
test.feature.dist2 <- function() {
  f1 <- sapply(letters[1:10], function(x) new('feature', feature=x, count=as.integer(1)))
  f2 <- sapply(letters[11:20], function(x) new('feature', feature=x, count=as.integer(1)))
  fv1 <- new('featvec', features=f1)
  fv2 <- new('featvec', features=f2)
  d <- distance(fv1, fv2, method='tanimoto')
  checkEquals(0, d)
}

test.featvec.read <- function() {
  data.file <- file.path(system.file("unitTests", "test.ecfp", package="fingerprint"))
  fps <- fp.read(data.file, lf=ecfp.lf, binary=FALSE)
  checkEquals(10, length(fps))

  lengths <- c(58L, 38L, 43L, 66L, 62L, 66L, 65L, 44L, 66L, 61L)
  ol <- sapply(fps, length)
  checkTrue(identical(lengths, ol))
}

tester.getters.setters <- function() {
  f <- new("feature", feature='ABCD', count=as.integer(1))
  checkEquals("ABCD", feature(f))
  checkEquals(1, count(f))

  feature(f) <- 'UXYZ'
  count(f) <- 10
  checkEquals("UXYZ", feature(f))
  checkEquals(10, count(f))
}
