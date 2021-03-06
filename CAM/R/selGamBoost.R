selGamBoost <-
function(X,pars = list(atLeastThatMuchSelected = 0.02, atMostThatManyNeighbors = 10),output = FALSE,k)
{
    if(output)
    {
        cat("Performing variable selection for variable", k, ": \n")
    }
    result <- list()
    p <- dim(as.matrix(X))
    if(p[2] > 1)
    {
        selVec <- rep(FALSE, p[2])
        modfitGam <- train_GAMboost(X[,-k],X[,k],pars)
        cc <- unique(modfitGam$model$xselect())
        if(output)
        {
            cat("The following variables \n")
            show(cc)
        }
        nstep <- length(modfitGam$model$xselect())
        howOftenSelected <- rep(NA,length(cc))
        for(i in 1:length(cc))
        {
            howOftenSelected[i] <- sum(modfitGam$model$xselect() == cc[i])/nstep
        }
        if(output)
        {
            cat("... have been selected that many times: \n")
            show(howOftenSelected)
        }
        howOftenSelectedSorted <- sort(howOftenSelected, decreasing = TRUE)
        if( sum(howOftenSelected>pars$atLeastThatMuchSelected) > pars$atMostThatManyNeighbors)
        {
            cc <- cc[howOftenSelected>howOftenSelectedSorted[pars$atMostThatManyNeighbors + 1]]
        } else
        {
            cc <- cc[howOftenSelected>pars$atLeastThatMuchSelected]
        }
        if(output)
        {
            cat("We finally choose as possible parents: \n")
            show(cc)
            cat("\n")
        }
        tmp <- rep(FALSE,p[2]-1)
        tmp[cc] <- TRUE
        selVec[-k] <- tmp
    } else
    {
        selVec <- list()
    }
    return(selVec)
}
