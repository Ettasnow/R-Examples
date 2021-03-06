waldConfidenceInterval_ir_stageOne <-
function(explanatory, response, Y_0, level=NA) {
	if (is.na(level)) {
		level <- 0.95
	}
	alpha <- 1 - level
	## Import previously computed Chernoff quantiles, provided by Groeneboom and Wellner
#	realizations <- read.table("results_chernoff", header=TRUE)
	chernoff_realizations <- NULL; rm(chernoff_realizations); # Dummy to trick R CMD check 
	data("chernoff_realizations", envir =environment())
	ind <- min(which(chernoff_realizations$DF - (1-alpha/2) >= 0))
	q <- chernoff_realizations$xcoor[ind]
	n <- length(response)
	
	fit <- threshold_estimate_ir(explanatory, response, Y_0)
	sigmaSq <- estimateSigmaSq(explanatory, response)$sigmaSq
	deriv_d0 <- estimateDeriv(explanatory, response, fit$threshold_estimate_explanatory, sigmaSq) 
	g_d0 <- 1/n

	n <- length(explanatory)
	C_di <- (4*sigmaSq / (deriv_d0^2) )^(1.0/3.0)
	band <- n^(-1.0/3.0) * C_di * g_d0^(-1.0/3.0) * q

	return(list(estimate=fit$threshold_estimate_explanatory,lower=max(min(explanatory),fit$threshold_estimate_explanatory - band), upper=min(max(explanatory),fit$threshold_estimate_explanatory + band), C_1 =as.numeric(C_di * g_d0^(-1.0/3.0) * q), sigmaSq=sigmaSq, deriv_d0=deriv_d0 ))
}
