phicom <- function(dset){
nitem <- ncol(dset)-1

test <- matrix(data = 0, nrow = factorial(nitem), ncol = nitem, byrow = TRUE)
temp1 <- 1:nitem
i <- 1
w <- rep(1,nitem)
modal <- 1:nitem

## generate a list of all possible rankings
for (j in 1:(nitem^nitem-1)){
temp1[1] <- nitem - j%%nitem
temp2 <- j - j%%nitem
for (k in nitem:2){
temp1[k] <- nitem - temp2%/%(nitem^(k-1))
temp2 <- temp2 - (nitem-temp1[k])*(nitem^(k-1))
}
temp2 <- 0
for (l in 1:nitem){
for (m in 1:nitem){
if (temp1[l] == temp1[m] && l != m){
temp2 <- 1
}
}
}
if (temp2 == 0){
for (p in 1:nitem){
test[i,p] = temp1[p]
}
i <- i+1
}
}

n <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
for (k in 1:nrow(dset)){
temp_ind <- 0
for (l in 1:nitem){
if (test[j,l] != dset[k,l]) {temp_ind <- temp_ind + 1}
}
if (temp_ind == 0) {n[j] <- dset[k,nitem+1]}
}
}
test2 <- cbind(test, n)

## define distance measure
rdist <- function(x,y){
d <- 0
for (j in 1:(nitem-1)){
for (k in (j+1):nitem){
if ((x[j]-x[k])*(y[j]-y[k]) < 0) {d <- d+1}
}
}
d
}

td <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
td[j] <- 0
for (k in 1:factorial(nitem)){
td[j] <- td[j] + n[k]*rdist(test[j,],test[k,])
}
}
test3 <- cbind(test2, td)

## compute modal ranking
modal <- rep(0,nitem)
temp1 <- max(td)
for (j in 1:factorial(nitem)){
if (td[j] == min(td)){
for (k in 1:nitem){
modal[k] <- test3[j,k]
}
}
}

## compute V
V <- matrix(data = 0, nrow = nrow(test2), ncol = nitem, byrow = TRUE)
for (i in 1:nrow(test2)){
for (j in 1:(nitem-1)){
for (k in (j+1):nitem){
if ((modal[j]-modal[k])*(test2[i,j]-test2[i,k]) < 0) {V[i,j] <- V[i,j]+1}
}
}
V[i,nitem] <- test2[i,(nitem+1)]
}

## loglikelihood function
loglik_dbm <- function(lambda){

ed <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
ed[j] <- exp(-(V[j,1:(nitem-1)]%*%lambda))
}
pc <- sum(ed)
pr <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
pr[j] <- ed[j]/pc
}
ll <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
ll[j] <- -log(pr[j])*test3[j,(nitem+1)]
}
sum(ll)
}

out1 <- optim(rep(1,(nitem-1)), loglik_dbm, NULL, method = "BFGS", hessian = TRUE)
##require(stats4)
## compute expected value
ed <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
ed[j] <- exp(-V[j,1:(nitem-1)]%*%out1$par)
}
pc <- sum(ed)
fitted <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
fitted[j] <- ed[j]/pc * sum(test3[,(nitem+1)])
}
ss <- rep(0,factorial(nitem))
for (j in 1:factorial(nitem)){
ss[j] <- (fitted[j] - test3[j,(nitem+1)])^2/fitted[j]
}

#lst <- list(modal.ranking=modal, loglik=out1$value, par=out1$par, se=(diag(solve(out1$hessian)))^0.5, fit.value=fitted, residual=sum(ss))
#return(lst)
message("Modal ranking: ", modal)
message("Chi-square residual statistic: ", round(sum(ss), digits = 2), ", df: ", factorial(nitem))
out2 <- new("mle")
out2@coef <- out1$par
out2@fullcoef <- out1$par
out2@vcov <- solve(out1$hessian)
out2@min <- out1$value
out2@details <- out1
out2@minuslogl <- loglik_dbm
out2@method <- "BFGS"
return(out2)
}