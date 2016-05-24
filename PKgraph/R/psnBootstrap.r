## PsN R script for plotting results of bootstrap
## Justin Wilkins
## October 2005
## Lars Lindbom
## August 2006, April 2007

## set basic options
## autogenerated code begins
## we can set other things, like colours, line types, layout, etc here if we wish

## This script assumes "ofv" is the last column before we get into the parameter estimates

psn.bootstrap <- function(file1, file2)
{
    min.failed    <- FALSE      # do we want to omit minimization failed runs?
    cov.failed    <- FALSE      # do we want to omit covariance failed runs?
    cov.warnings  <- TRUE       # do we want to omit covariance failed runs?
    boundary      <- TRUE       # do we want to omit boundary runs?
    showoriginal  <- TRUE       # show line for original estimate
    showmean      <- TRUE       # show line for mean
    showmedian    <- FALSE      # show line for median
    show95CI      <- TRUE       # show line for 95 % confidence interval (percentile)
    showquart     <- FALSE      # show line for quartiles

    excl.id <- c()              # exclude samples that have this individual

    ## autogenerated code ends

    ## read files
    bootstrap.data <- read.csv(file1, header=T) # read.csv("raw_results1.csv", header=T)
    incl.ids       <- read.csv(file2, header=F) # read.csv("included_individuals1.csv", header=F)

    ## replace underscores
    for (i in 1:length(names(bootstrap.data))) {
      names(bootstrap.data)[i] <- gsub("_", ".", names(bootstrap.data)[i])
    }

    ## find ofv column index
    index <- 0
    seen  <- FALSE

    for (i in names(bootstrap.data)) {
      if (!seen) {
        index <- index + 1
      }
      if (i == "ofv") {
        seen <- TRUE
      }
    }

    ## get number of parameters
    n       <- length(colnames(bootstrap.data)) - index
    nparams <- length(colnames(bootstrap.data))

    ## separate out original model fit
    p1 <- subset(bootstrap.data, bootstrap.data$model != 0)
    o1 <- subset(bootstrap.data, bootstrap.data$model == 0)

    incl.flag <- rep(0,length(rownames(p1)))
    for( i in excl.id ) {
      incl.flag <- incl.flag + rowSums( incl.ids == i )
    }

    p1 <- p1[(incl.flag==0),]

    #names(p1)[2] <- "minimization.successful"
    #names(p1)[3] <- "covariance.step.successful"
    #names(p1)[4] <- "covariance.step.warnings"
    #names(p1)[5] <- "estimate.near.boundary"

    #cat(nrow(p1))
    if (min.failed) {
      p1 <- subset(p1, minimization.successful == 1)
    }
    if (cov.failed) {
      p1 <- subset(p1, covariance.step.successful == 1)
    }
    if (cov.warnings) {
      p1 <- subset(p1, covariance.step.warnings == 0)
    }
    if (boundary) {
      p1 <- subset(p1, estimate.near.boundary == 0)
    }

    ## stats and plots for each- single

    for (i in index:nparams) {
      if (mode(p1[[i]]) == "numeric" &&
          sum(p1[[i]],na.rm=T)) {
        sp <- summary(p1[[i]])
        # IQR <- diff(summary(p1[[i]])[c(5,2)])
        dp <- density(p1[[i]], na.rm=T)
        parmlabel <- names(p1)[i]

        #pdf(file=paste("bootstrap.", parmlabel, ".pdf", sep=""), paper="special",
        #  title=paste("Bootstrap results - ", parmlabel, sep=""),width=10,height=7 )

        qu <- quantile(p1[[i]], c(0.025, 0.975), na.rm=T)

        legend=paste("n = ", nrow(p1), sep="")
        if (showmean) {
          legend=paste(legend, "; Mean = ", sp[4], sep="")
        }
        if (showmedian) {
          legend=paste(legend, "; Median = ", sp[3], sep="")
        }
        if (showoriginal) {
          legend=paste(legend, "; Orig = ", o1[[i]], sep="")
        }
######################################
    pgraph = ggraphics(ps=6)
    add(pk.dialog.notebook, pgraph, label = message,
          override.closebutton = FALSE)
######################################

        hist(p1[[i]],
              main = paste("Bootstrap results - ", parmlabel, sep=""),
              xlab = parmlabel,
              # ylim = c(0, max(dp$y)),
              # ylim = c(0, 1),
              xlim = c(min(dp$x), max(dp$x)),
              breaks = 20,
              # xlim = c(min(p1[[i]]) - min(p1[[i]])*0.15,max(p1[[i]]) + max(p1[[i]])*0.15),
              probability = T,
              sub=legend )
    #          sub=paste(paste(paste("n = ", nrow(p1), sep=""), "; Median = ", sp[4], sep=""), "; Orig = ", o1[[i]], sep="") )

        #h <- hist(p1[[i]], prob=T, plot=F)

        lines(dp, lwd=2, lty=3, col="red")

        if (showquart) {
          abline(v=sp[2], lwd= 1, lty=3, col="red") ## 1st quartile
          abline(v=sp[5], lwd= 1, lty=3, col="red") ## 3rd quartile
        }
        if (showmean) {
          abline(v=sp[4], lty=2, lwd=1, col="red") ## mean
        }
        if (showmedian) {
          abline(v=sp[3], lty=1, lwd=2, col="red") ## median
        }
        if (showoriginal) {
          abline(v=o1[[i]], lty=2, lwd=1, col="red") ## original
        }
        if (show95CI) {
          abline(v=qu[1], lty=4, lwd=1, col="red") ## 2.5% CL
          abline(v=qu[2], lty=4, lwd=1, col="red") ## 97.5% CL
          text(qu[1], max(dp$y), labels=signif(qu[1], digits = 3), cex = .8, adj = c(0,0), pos='2')
          text(qu[2], max(dp$y), labels=signif(qu[2], digits = 3), cex = .8, adj = c(0,0), pos='4')
        }
    #    abline(v=sp[4], lty=1, lwd=2, col="red") ## median
    #    abline(v=o1[[i]], lty=2, lwd=1, col="red") ## original
    #    abline(v=qu[1], lty=4, lwd=1, col="red") ## 2.5% CL
    #    abline(v=qu[2], lty=4, lwd=1, col="red") ## 97.5% CL

    #    text(qu[1], max(dp$y), labels=signif(qu[1], digits = 3), cex = .8, adj = c(0,0), pos='2')
    #    text(qu[2], max(dp$y), labels=signif(qu[2], digits = 3), cex = .8, adj = c(0,0), pos='4')
        #text(sp[4], max(h$density), labels=paste("Med: ", signif(sp[4], digits = 3), sep=""), adj = c(-1,0), cex = .8, pos='2')
      }
    }

    ## stats and plots for each - 6 per sheet

    total  <- 0
    bspage <- 0

    for (i in index:nparams) {
      if (mode(p1[[i]]) == "numeric" &&
          sum(p1[[i]],na.rm=T)) {
        sp <- summary(p1[[i]])
        # IQR <- diff(summary(p1[[i]])[c(5,2)])
        dp <- density(p1[[i]], na.rm=T)
        parmlabel <- names(p1)[i]

        if (total == 0) {
          bspage <- bspage + 1
          #pdf(file=paste("bootstrap.page", bspage, ".pdf", sep=""), paper="special",
           # title="Bootstrap results",width=10,height=7)
          par(mfrow = c(3,3))
        }
        total <- total + 1

        qu <- quantile(p1[[i]], c(0.025, 0.975), na.rm=T)

        legend=paste("n = ", nrow(p1), sep="")
        if (showmean) {
          legend=paste(legend, "; Mean = ", sp[3], sep="")
        }
        if (showmedian) {
          legend=paste(legend, "; Median = ", sp[4], sep="")
        }
        if (showoriginal) {
          legend=paste(legend, "; Orig = ", o1[[i]], sep="")
        }
        
######################################
    pgraph = ggraphics(ps=6)
    add(pk.dialog.notebook, pgraph, label = message,
          override.closebutton = FALSE)
######################################

        hist(p1[[i]],
              main = paste("Bootstrap results - ", parmlabel, sep=""),
              xlab = parmlabel,
              # ylim = c(0, max(dp$y)),
              # ylim = c(0, 1),
              xlim = c(min(dp$x), max(dp$x)),
              breaks = 20,
              # xlim = c(min(p1[[i]]) - min(p1[[i]])*0.15,max(p1[[i]]) + max(p1[[i]])*0.15),
              probability = T,
              sub=legend )
    #=paste(paste(paste("n = ", nrow(p1), sep=""), "; Median = ", sp[4], sep=""), "; Orig = ", o1[[i]], sep="") )

        #h <- hist(p1[[i]], prob=T, plot=F)

        lines(dp, lwd=2, lty=3, col="red")

        if (showquart) {
          abline(v=sp[2], lwd= 1, lty=3, col="red") ## 1st quartile
          abline(v=sp[5], lwd= 1, lty=3, col="red") ## 3rd quartile
        }
        if (showmean) {
          abline(v=sp[3], lty=2, lwd=1, col="red") ## mean
        }
        if (showmedian) {
          abline(v=sp[4], lty=1, lwd=2, col="red") ## median
        }
        if (showoriginal) {
          abline(v=o1[[i]], lty=2, lwd=1, col="red") ## original
        }
        if (show95CI) {
          abline(v=qu[1], lty=4, lwd=1, col="red") ## 2.5% CL
          abline(v=qu[2], lty=4, lwd=1, col="red") ## 97.5% CL
          text(qu[1], max(dp$y), labels=signif(qu[1], digits = 3), cex = .8, adj = c(0,0), pos='2')
          text(qu[2], max(dp$y), labels=signif(qu[2], digits = 3), cex = .8, adj = c(0,0), pos='4')
        }

    #    abline(v=sp[4], lty=1, lwd=2, col="red") ## median
    #    abline(v=o1[[i]], lty=2, lwd=1, col="red") ## original
    #    abline(v=qu[1], lty=4, lwd=1, col="red") ## 2.5% CL
    #    abline(v=qu[2], lty=4, lwd=1, col="red") ## 97.5% CL

    #    text(qu[1], max(dp$y), labels=signif(qu[1], digits = 3), cex = .8, adj = c(0,0), pos='2')
    #    text(qu[2], max(dp$y), labels=signif(qu[2], digits = 3), cex = .8, adj = c(0,0), pos='4')
        #text(sp[4], max(h$density), labels=paste("Med: ", signif(sp[4], digits = 3), sep=""), adj = c(-1,0), cex = .8, pos='2')

        if (total == 9) {
          total <- 0
          #dev.off()
        }
      }
    }

}