gaussian.dissimilarityCAR <-
function(formula, data=NULL, W, Z, burnin, n.sample, thin=1, prior.mean.beta=NULL, prior.var.beta=NULL, prior.nu2=NULL, prior.tau2=NULL, verbose=TRUE)
{
#### Check on the verbose option
     if(is.null(verbose)) verbose=TRUE     
     if(!is.logical(verbose)) stop("the verbose option is not logical.", call.=FALSE)

     if(verbose)
     {
     cat("Setting up the model\n")
     a<-proc.time()
     }else{}

##############################################
#### Format the arguments and check for errors
##############################################
#### Overall formula object
frame <- try(suppressWarnings(model.frame(formula, data=data, na.action=na.pass)), silent=TRUE)
if(class(frame)=="try-error") stop("the formula inputted contains an error, e.g the variables may be different lengths.", call.=FALSE)



#### Design matrix
## Create the matrix
X <- try(suppressWarnings(model.matrix(object=attr(frame, "terms"), data=frame)), silent=TRUE)
     if(class(X)=="try-error") stop("the covariate matrix contains inappropriate values.", call.=FALSE)
     if(sum(is.na(X))>0) stop("the covariate matrix contains missing 'NA' values.", call.=FALSE)

n <- nrow(X)
p <- ncol(X)

## Check for linearly related columns
cor.X <- suppressWarnings(cor(X))
diag(cor.X) <- 0

    if(max(cor.X, na.rm=TRUE)==1) stop("the covariate matrix has two exactly linearly related columns.", call.=FALSE)
    if(min(cor.X, na.rm=TRUE)==-1) stop("the covariate matrix has two exactly linearly related columns.", call.=FALSE)
 
 	 if(p>1)
	 {
    	     if(sort(apply(X, 2, sd))[2]==0) stop("the covariate matrix has two intercept terms.", call.=FALSE)
	 }else
	 {
	 }
 
## Standardise the matrix
X.standardised <- X
X.sd <- apply(X, 2, sd)
X.mean <- apply(X, 2, mean)
X.indicator <- rep(NA, p)       # To determine which parameter estimates to transform back

    for(j in 1:p)
    {
        if(length(table(X[ ,j]))>2)
        {
        X.indicator[j] <- 1
        X.standardised[ ,j] <- (X[ ,j] - mean(X[ ,j])) / sd(X[ ,j])
        }else if(length(table(X[ ,j]))==1)
        {
        X.indicator[j] <- 2
        }else
        {
        X.indicator[j] <- 0
        }
    }



#### Dissimilarity metric matrix
## Check the list of dissimilarity metrics is appropriate
    if(class(Z)!="list") stop("Z is not a list object.", call.=FALSE)
    if(sum(is.na(as.numeric(lapply(Z, sum, na.rm=FALSE))))>0) stop("Z contains missing 'NA' values.", call.=FALSE)

q <- length(Z)

	if(sum(as.character(lapply(Z,class))=="matrix")<q) stop("Z contains non-matrix values.", call.=FALSE)
	if(sum(as.numeric(lapply(Z,nrow))==n) <q) stop("Z contains matrices of the wrong size.", call.=FALSE)
	if(sum(as.numeric(lapply(Z,ncol))==n) <q) stop("Z contains matrices of the wrong size.", call.=FALSE)
	if(min(as.numeric(lapply(Z,min)))<0) stop("Z contains negative values.", call.=FALSE)


## Determine the default values for the maximums for alpha and the threshold values to be significant
alpha.max <- rep(NA,q)
alpha.threshold <- rep(NA,q)
	for(k in 1:q)
	{
	Z.crit <- quantile(as.numeric(Z[[k]])[as.numeric(Z[[k]])!=0], 0.5)
	alpha.max[k] <- -log(0.5) / Z.crit
	alpha.threshold[k] <- -log(0.5) / max(Z[[k]])
	}



#### Response variable
## Create the response
Y <- model.response(frame)
which.miss <- as.numeric(!is.na(Y))
n.miss <- n - sum(which.miss)
Y.miss <- Y
Y.miss[which.miss==0] <- median(Y, na.rm=TRUE)
Y.short <- Y[which.miss==1]
X.short <- X.standardised[which.miss==1, ]

## Check for errors
    if(!is.numeric(Y)) stop("the response variable has non-numeric values.", call.=FALSE)



#### Offset variable
## Create the offset
offset <- try(model.offset(frame), silent=TRUE)

## Check for errors
    if(class(offset)=="try-error")   stop("the offset is not numeric.", call.=FALSE)
    if(is.null(offset))  offset <- rep(0,n)
    if(sum(is.na(offset))>0) stop("the offset has missing 'NA' values.", call.=FALSE)
    if(!is.numeric(offset)) stop("the offset variable has non-numeric values.", call.=FALSE)
offset.short <- offset[which.miss==1]


#### Initial parameter values
mod.glm <- lm(Y~X.standardised-1, offset=offset)
beta.mean <- mod.glm$coefficients
beta.sd <- sqrt(diag(summary(mod.glm)$cov.unscaled)) * summary(mod.glm)$sigma
beta <- rnorm(n=length(beta.mean), mean=beta.mean, sd=beta.sd)

res.temp <- Y - X.standardised %*% beta.mean - offset
res.sd <- sd(res.temp, na.rm=TRUE)/5
phi <- rnorm(n=n, mean=rep(0,n), sd=res.sd)
tau2 <- var(phi) / 10
nu2 <- tau2
alpha <- runif(n=q, min=rep(0,q), max=(alpha.max/(2+q))) 


#### Priors
## Put in default priors
    if(is.null(prior.mean.beta)) prior.mean.beta <- rep(0, p)
    if(is.null(prior.var.beta)) prior.var.beta <- rep(1000, p)
    if(is.null(prior.tau2)) prior.tau2 <- c(1, 0.01)
    if(is.null(prior.nu2)) prior.nu2 <- c(1, 0.01)

    
## Checks    
    if(length(prior.mean.beta)!=p) stop("the vector of prior means for beta is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.mean.beta)) stop("the vector of prior means for beta is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.mean.beta))!=0) stop("the vector of prior means for beta has missing values.", call.=FALSE)    
 
    if(length(prior.var.beta)!=p) stop("the vector of prior variances for beta is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.var.beta)) stop("the vector of prior variances for beta is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.var.beta))!=0) stop("the vector of prior variances for beta has missing values.", call.=FALSE)    
    if(min(prior.var.beta) <=0) stop("the vector of prior variances has elements less than zero", call.=FALSE)
 
    if(length(prior.tau2)!=2) stop("the prior value for tau2 is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.tau2)) stop("the prior value for tau2 is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.tau2))!=0) stop("the prior value for tau2 has missing values.", call.=FALSE)    
   
    if(length(prior.nu2)!=2) stop("the prior value for nu2 is the wrong length.", call.=FALSE)    
    if(!is.numeric(prior.nu2)) stop("the prior value for nu2 is not numeric.", call.=FALSE)    
    if(sum(is.na(prior.nu2))!=0) stop("the prior value for nu2 has missing values.", call.=FALSE)    


#### MCMC quantities
## Checks
if(is.null(burnin)) stop("the burnin argument is missing", call.=FALSE)
if(is.null(n.sample)) stop("the n.sample argument is missing", call.=FALSE)
if(!is.numeric(burnin)) stop("burn-in is not a number", call.=FALSE)
if(!is.numeric(n.sample)) stop("n.sample is not a number", call.=FALSE) 
if(!is.numeric(thin)) stop("thin is not a number", call.=FALSE)
if(n.sample <= 0) stop("n.sample is less than or equal to zero.", call.=FALSE)
if(burnin < 0) stop("burn-in is less than zero.", call.=FALSE)
if(thin <= 0) stop("thin is less than or equal to zero.", call.=FALSE)
if(n.sample <= burnin)  stop("Burn-in is greater than n.sample.", call.=FALSE)
if(n.sample <= thin)  stop("thin is greater than n.sample.", call.=FALSE)
if(burnin!=round(burnin)) stop("burnin is not an integer.", call.=FALSE) 
if(n.sample!=round(n.sample)) stop("n.sample is not an integer.", call.=FALSE) 
if(thin!=round(thin)) stop("thin is not an integer.", call.=FALSE) 


## Matrices to store samples
n.keep <- floor((n.sample - burnin)/thin)
samples.beta <- array(NA, c(n.keep, p))
samples.phi <- array(NA, c(n.keep, n))
samples.nu2 <- array(NA, c(n.keep, 1))
samples.tau2 <- array(NA, c(n.keep, 1))
samples.alpha <- array(NA, c(n.keep, q))
samples.deviance <- array(NA, c(n.keep, 1))
samples.like <- array(NA, c(n.keep, n))
samples.fitted <- array(NA, c(n.keep, n))
if(n.miss>0) samples.Y <- array(NA, c(n.keep, n.miss))

     
## Metropolis quantities
accept <- c(0,0)
accept.all <- c(0,0)
proposal.sd.alpha <- 0.02 * alpha.max
tau2.posterior.shape <- prior.tau2[1] + 0.5*(n-1)
nu2.posterior.shape <- prior.nu2[1] + 0.5*(n-n.miss)  


#### Checks for the original W matrix
    if(!is.matrix(W)) stop("W is not a matrix.", call.=FALSE)
    if(nrow(W)!= n) stop("W has the wrong number of rows.", call.=FALSE)
    if(ncol(W)!= n) stop("W has the wrong number of columns.", call.=FALSE)
    if(sum(is.na(W))>0) stop("W has missing 'NA' values.", call.=FALSE)
    if(!is.numeric(W)) stop("W has non-numeric values.", call.=FALSE)
    if(!sum(names(table(W))==c(0,1))==2) stop("W has non-binary (zero and one) values.", call.=FALSE)
    if(!is.symmetric.matrix(W)) stop("W is not symmetric.", call.=FALSE)
    if(min(apply(W, 1, sum))==0) stop("W has some areas with no neighbours (one of the row sums equals zero).", call.=FALSE)    


## Ensure the W matrix is symmetric
Wnew <- array(0, c(n,n))
     for(i in 1:n)
     {
          for(j in 1:n)
          {
               if(i>j)
               {
               temp <- W[i,j]
               Wnew[i,j] <- temp
               Wnew[j,i] <- temp
               }else{}
          }
     }
W <- Wnew  
n.neighbours <- apply(W, 2, sum)
spam.W <- as.spam(W)
     
     
## Create the triplet object
W.triplet <- c(NA, NA, NA)
     for(i in 1:n)
     {
          for(j in 1:n)
          {
               if(W[i,j]==1)
               {
               W.triplet <- rbind(W.triplet, c(i,j, NA))     
               }else{}
          }
     }
W.triplet <- W.triplet[-1, ]     
n.triplet <- nrow(W.triplet) 

     
     
## Create the start and finish points for W updating
W.begfin <- array(NA, c(n, 2))     
temp <- 1
     for(i in 1:n)
     {
     W.begfin[i, ] <- c(temp, (temp + n.neighbours[i]-1))
     temp <- temp + n.neighbours[i]
     }
     
     
## Create the Z triplet form
Z.triplet <- array(NA, c(n.triplet, q))
     for(i in 1:n.triplet)
     {
     row <- W.triplet[i,1]
     col <- W.triplet[i,2]
          for(j in 1:q)
          {
          Z.triplet[i,j] <- Z[[j]][row, col]     
          }     
     }
W.triplet[ ,3] <- as.numeric(exp(-Z.triplet %*% alpha)>=0.5)
W.triplet.sum <- tapply(W.triplet[ ,3], W.triplet[ ,1], sum)
spam.W@entries <- W.triplet[ ,3]      
spam.Wprop <- spam.W     
W.tripletprop <- W.triplet

     
     
#### Create the matrix form of Q
rho <- 0.99
Q <- -rho * spam.W 
diag(Q) <- rho * rowSums(spam.W) + 1-rho
det.Q <- sum(log(diag(chol.spam(Q))))     


#### Beta update quantities
data.precision.beta <- t(X.short) %*% X.short
	if(length(prior.var.beta)==1)
	{
	prior.precision.beta <- 1 / prior.var.beta
	}else
	{
	prior.precision.beta <- solve(diag(prior.var.beta))
	}



###########################
#### Run the Bayesian model
###########################
## Start timer
     if(verbose)
     {
         cat("Generating", n.keep, "post burnin and thinned (if requested) samples\n", sep = " ")
     progressBar <- txtProgressBar(style = 3)
     percentage.points<-round((1:100/100)*n.sample)
     }else
     {
     percentage.points<-round((1:100/100)*n.sample)     
     }
     
          for(j in 1:n.sample)
    	     {
		####################
		## Sample from beta
		####################
		fc.precision <- prior.precision.beta + data.precision.beta / nu2
		fc.var <- solve(fc.precision)
		beta.offset <- as.numeric(Y.short - offset.short - phi[which.miss==1])
		beta.offset2 <- t(X.short) %*% beta.offset / nu2 + prior.precision.beta %*% prior.mean.beta
		fc.mean <- fc.var %*% beta.offset2
		chol.var <- t(chol(fc.var))
		beta <- fc.mean + chol.var %*% rnorm(p)  

		
		
		##################
		## Sample from nu2
		##################
           fitted.current <-  as.numeric(X.short %*% beta) + phi[which.miss==1] + offset.short
          nu2.posterior.scale <- prior.nu2[2] + 0.5 * sum((Y.short - fitted.current)^2)
          nu2 <- 1 / rgamma(1, nu2.posterior.shape, scale=(1/nu2.posterior.scale)) 

		####################
		## Sample from phi
		####################
          offset.phi <- (Y.miss - as.numeric(X.standardised %*% beta) - offset) / nu2    
          phi <- gaussiancarupdate(Wtriplet=W.triplet, Wbegfin=W.begfin, W.triplet.sum, nsites=n, phi=phi, tau2=tau2, rho=rho, nu2=nu2, offset=offset.phi, which.miss)
          phi <- phi - mean(phi)
		

    
		##################
		## Sample from tau2
		##################
          temp2 <- quadform(W.triplet, W.triplet.sum, n.triplet, n, phi, phi, rho)
          tau2.posterior.scale <- temp2 + prior.tau2[2] 
          tau2 <- 1 / rgamma(1, tau2.posterior.shape, scale=(1/tau2.posterior.scale))		
    
 
        	######################
		#### Sample from alpha
		######################
    	     ## Propose a value
          proposal.alpha <- alpha
    	          for(r in 1:q)
    	          {
    	          proposal.alpha[r] <- rtrunc(n=1, spec="norm", a=0, b=alpha.max[r],  mean=alpha[r], sd=proposal.sd.alpha[r])
    	          }
               
          ## Create the proposal values for W and Q
          W.tripletprop[ ,3] <- as.numeric(exp(-Z.triplet %*% proposal.alpha)>=0.5)
          W.triplet.sum.prop <- tapply(W.tripletprop[ ,3], W.tripletprop[ ,1], sum)
          spam.Wprop@entries <- W.tripletprop[ ,3]     
          Qprop <- -rho * spam.Wprop 
          diag(Qprop) <- rho * rowSums(spam.Wprop) + 1-rho
          det.Qprop <- sum(log(diag(chol.spam(Qprop))))     
          temp3 <- quadform(W.tripletprop, W.triplet.sum.prop, n.triplet, n, phi, phi, rho)              
               
          #### Calculate the acceptance probability
    	     logprob.current <- det.Q - temp2 / tau2
    	     logprob.proposal <- det.Qprop - temp3 / tau2
          prob <- exp(logprob.proposal - logprob.current)
    	     
    	     #### Accept or reject the proposed value
    	          if(prob > runif(1))
    	          {
    	          alpha <- proposal.alpha
    	          det.Q <- det.Qprop 
               W.triplet[ ,3] <- W.tripletprop[ ,3]
               W.triplet.sum <- W.triplet.sum.prop
               accept[1] <- accept[1] + 1
    	          }else
    	          {
    	          }  
    	     accept[2] <- accept[2] + 1     
		
      
             
    	     #########################
    	     ## Calculate the deviance
    	     #########################
    	     fitted <- as.numeric(X.standardised %*% beta) + phi + offset
    	     deviance.all <- dnorm(Y, mean = fitted, sd = rep(sqrt(nu2),n), log=TRUE)
    	     like <- exp(deviance.all)
    	     deviance <- -2 * sum(deviance.all, na.rm=TRUE)  

    	     
    	     ###################
    	     ## Save the results
    	     ###################
               if(j > burnin & (j-burnin)%%thin==0)
               {
               ele <- (j - burnin) / thin
               samples.beta[ele, ] <- beta
               samples.phi[ele, ] <- phi
               samples.nu2[ele, ] <- nu2
               samples.tau2[ele, ] <- tau2
               samples.alpha[ele, ] <- alpha
               samples.deviance[ele, ] <- deviance
               samples.like[ele, ] <- like
               samples.fitted[ele, ] <- fitted
               if(n.miss>0) samples.Y[ele, ] <- rnorm(n=n.miss, mean=fitted[which.miss==0], sd=sqrt(nu2))
               }else
               {
               }

    
		    ########################################
		    ## Self tune the acceptance probabilties
		    ########################################
		    k <- j/100
		        if(ceiling(k)==floor(k))
		        {
		        #### Determine the acceptance probabilities
		        accept.alpha <- 100 * accept[1] / accept[2]
		        accept.all <- accept.all + accept
		        accept <- c(0,0)
		    
		        #### alpha tuning parameter
		            if(accept.alpha > 50)
		            {
		            proposal.sd.alpha <- min(proposal.sd.alpha + 0.1 * proposal.sd.alpha, alpha.max/4)
		            }else if(accept.alpha < 40)              
		            {
		            proposal.sd.alpha <- proposal.sd.alpha - 0.1 * proposal.sd.alpha
		            }else
		            {
		            }
		    }else
		    {   
		    }
		
          ################################       
          ## print progress to the console
          ################################
               if(j %in% percentage.points & verbose)
               {
               setTxtProgressBar(progressBar, j/n.sample)
               }
   		}


# end timer
     if(verbose)
     {
     cat("\nSummarising results")
     close(progressBar)
     }else
     {}
     
###################################
#### Summarise and save the results 
###################################
## Acceptance rates
accept.alpha <- 100 * accept.all[1] / accept.all[2]
accept.final <- c(100, 100, 100, 100, accept.alpha)
names(accept.final) <- c("beta", "phi", "nu2", "tau2", "alpha")
 
        
## Deviance information criterion (DIC)
median.beta <- apply(samples.beta, 2, median)
median.phi <- apply(samples.phi, 2, median)
fitted.median <- X.standardised %*% median.beta + median.phi + offset
nu2.median <- median(samples.nu2)
deviance.fitted <- -2 * sum(dnorm(Y, mean = fitted.median, sd = rep(sqrt(nu2.median),n), log = TRUE), na.rm=TRUE)
p.d <- median(samples.deviance) - deviance.fitted
DIC <- 2 * median(samples.deviance) - deviance.fitted    
   
   
#### Watanabe-Akaike Information Criterion (WAIC)
LPPD <- sum(log(apply(samples.like,2,mean)), na.rm=TRUE)
p.w <- sum(apply(log(samples.like),2,var), na.rm=TRUE)
WAIC <- -2 * (LPPD - p.w)


#### Compute the Conditional Predictive Ordinate
CPO <- rep(NA, n)
     for(j in 1:n)
     {
     CPO[j] <- 1/median((1 / dnorm(Y[j], mean=samples.fitted[ ,j], sd=sqrt(samples.nu2))))    
     }
LMPL <- sum(log(CPO), na.rm=TRUE)   
     

#### transform the parameters back to the origianl covariate scale.
samples.beta.orig <- samples.beta
number.cts <- sum(X.indicator==1)     
if(number.cts>0)
{
  for(r in 1:p)
  {
    if(X.indicator[r]==1)
    {
      samples.beta.orig[ ,r] <- samples.beta[ ,r] / X.sd[r]
    }else if(X.indicator[r]==2 & p>1)
    {
      X.transformed <- which(X.indicator==1)
      samples.temp <- as.matrix(samples.beta[ ,X.transformed])
      for(s in 1:length(X.transformed))
      {
        samples.temp[ ,s] <- samples.temp[ ,s] * X.mean[X.transformed[s]]  / X.sd[X.transformed[s]]
      }
      intercept.adjustment <- apply(samples.temp, 1,sum) 
      samples.beta.orig[ ,r] <- samples.beta[ ,r] - intercept.adjustment
    }else
    {
    }
  }
}else
{
}



#### Create a summary object
samples.beta.orig <- mcmc(samples.beta.orig)
summary.beta <- t(apply(samples.beta.orig, 2, quantile, c(0.5, 0.025, 0.975))) 
summary.beta <- cbind(summary.beta, rep(n.keep, p), rep(100,p), effectiveSize(samples.beta.orig), geweke.diag(samples.beta.orig)$z)
rownames(summary.beta) <- colnames(X)
colnames(summary.beta) <- c("Median", "2.5%", "97.5%", "n.sample", "% accept", "n.effective", "Geweke.diag")

samples.alpha <- mcmc(samples.alpha)
summary.alpha <- t(apply(samples.alpha, 2, quantile, c(0.5, 0.025, 0.975))) 
summary.alpha <- cbind(summary.alpha, rep(n.keep, q), rep(accept.alpha,q), effectiveSize(samples.alpha), geweke.diag(samples.alpha)$z)


	if(!is.null(names(Z)))
 	{
 	rownames(summary.alpha) <- names(Z)
	}else
	{
	names.Z <- rep(NA,q)
		for(j in 1:q)
		{
		names.Z[j] <- paste("Z[[",j, "]]", sep="")
		}	
	rownames(summary.alpha) <- names.Z	
	}



summary.hyper <- array(NA, c(2 ,7))
summary.hyper[1, 1:3] <- quantile(samples.nu2, c(0.5, 0.025, 0.975))
summary.hyper[1, 4:7] <- c(n.keep, 100, effectiveSize(samples.nu2), geweke.diag(samples.nu2)$z)
summary.hyper[2, 1:3] <- quantile(samples.tau2, c(0.5, 0.025, 0.975))
summary.hyper[2, 4:7] <- c(n.keep, 100, effectiveSize(samples.tau2), geweke.diag(samples.tau2)$z)

summary.results <- rbind(summary.beta, summary.hyper, summary.alpha)
alpha.min <- c(rep(NA, (p+2)), alpha.threshold)
summary.results <- cbind(summary.results, alpha.min)
rownames(summary.results)[(p+1):(p+2)] <- c("nu2", "tau2")
summary.results[ , 1:3] <- round(summary.results[ , 1:3], 4)
summary.results[ , 4:7] <- round(summary.results[ , 4:7], 1)
summary.results[ , 8] <- round(summary.results[ , 8], 4)



#### Create the Fitted values and residuals
fitted.values <- apply(samples.fitted, 2, median)
residuals <- as.numeric(Y) - fitted.values

 
#### Create the posterior medians for the neighbourhood matrix W
W.posterior <- array(NA, c(n,n))
W.border.prob <- array(NA, c(n,n))
	for(i in 1:n)
	{
		for(j in 1:n)
		{
			if(W[i,j]==1)
			{
			z.temp <- NA
				for(k in 1:q)
				{
				z.temp <- c(z.temp, Z[[k]][i,j])
				}	
			z.temp <- z.temp[-1]
			w.temp <- exp(-samples.alpha %*% z.temp)
			w.posterior <- as.numeric(w.temp>=0.5)
			W.posterior[i,j] <- ceiling(median(w.posterior))
			W.border.prob[i,j] <- (1 - sum(w.posterior) / length(w.posterior))
			}else
			{
			}	
		}	
	}



## Compile and return the results
modelfit <- c(DIC, p.d, WAIC, p.w, LMPL)
names(modelfit) <- c("DIC", "p.d", "WAIC", "p.w", "LMPL")
model.string <- c("Likelihood model - Gaussian (identity link function)", "\nRandom effects model - Localised CAR", "\nDissimilarity metrics - ", rownames(summary.alpha), "\n")     
if(n.miss==0) samples.Y = NA

samples <- list(beta=samples.beta.orig, phi=mcmc(samples.phi), tau2=mcmc(samples.tau2), nu2=mcmc(samples.nu2), alpha=mcmc(samples.alpha), fitted=mcmc(samples.fitted), Y=mcmc(samples.Y))
results <- list(summary.results=summary.results, samples=samples, fitted.values=fitted.values, residuals=residuals, modelfit=modelfit, accept=accept.final, localised.structure=list(W.posterior=W.posterior, W.border.prob=W.border.prob),  formula=formula, model=model.string, X=X)
class(results) <- "carbayes"

     if(verbose)
     {
     b<-proc.time()
     cat(" finished in ", round(b[3]-a[3], 1), "seconds")
     }else
     {}
return(results)
}
