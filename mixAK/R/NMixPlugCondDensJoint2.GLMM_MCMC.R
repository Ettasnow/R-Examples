##
##  PURPOSE:   Computation of the conditional pairwise bivariate densities given one margin
##             (plug-in version)
##              * method for objects of class GLMM_MCMC
##
##  AUTHOR:    Arnost Komarek (LaTeX: Arno\v{s}t Kom\'arek)
##             arnost.komarek[AT]mff.cuni.cz
##
##  CREATED:   24/07/2009
##
##  FUNCTIONS: NMixPlugCondDensJoint2.GLMM_MCMC (24/07/2009)
##             
## ======================================================================

## *************************************************************
## NMixPlugCondDensJoint2.GLMM_MCMC
## *************************************************************
NMixPlugCondDensJoint2.GLMM_MCMC <- function(x, icond, grid, lgrid=50, scaled=FALSE, ...)
{
  if (missing(icond)) stop("icond must be given")
  if (x$dimb == 1) stop("not applicable for univariate mixtures")  
  if (x$prior.b$priorK != "fixed") stop("only implemented for models with fixed number of components")
  
  if (missing(grid)){
    grid <- list()
    if (scaled){
      if (x$dimb == 1){
        rangeGrid <- 0 + c(-3.5, 3.5)*1
        grid[[1]] <- seq(rangeGrid[1], rangeGrid[2], length=lgrid)      
      }else{     
        for (i in 1:x$dimb){
          rangeGrid <- 0 + c(-3.5, 3.5)*1
          grid[[i]] <- seq(rangeGrid[1], rangeGrid[2], length=lgrid)
        }
      }  
    }else{
      if (x$dimb == 1){
        rangeGrid <- x$summ.b.Mean["Median"] + c(-3.5, 3.5)*x$summ.b.SDCorr["Median"]
        grid[[1]] <- seq(rangeGrid[1], rangeGrid[2], length=lgrid)      
      }else{     
        for (i in 1:x$dimb){
          rangeGrid <- x$summ.b.Mean["Median", i] + c(-3.5, 3.5)*x$summ.b.SDCorr["Median", (i-1)*(2*x$dim - i + 2)/2 + 1]
          grid[[i]] <- seq(rangeGrid[1], rangeGrid[2], length=lgrid)
        }
      }  
    }
    names(grid) <- paste("b", 1:x$dimb, sep="")    
  }

  if (x$dimb == 1) if (is.numeric(grid)) grid <- list(b1=grid)
  if (!is.list(grid)) stop("grid must be a list")

  if (scaled) scale <- list(shift=0, scale=1)  
  else        scale <- x$scale.b
  
  return(NMixPlugCondDensJoint2.default(x=grid, icond=icond, scale=scale, w=x$poster.mean.w_b, mu=x$poster.mean.mu_b, Sigma=x$poster.mean.Sigma_b))
}  
