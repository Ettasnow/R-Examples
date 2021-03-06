### This is for simulation only, plotting against true values.

rm(list = ls())

suppressMessages(library(cubfits, quietly = TRUE))

source("00-set_env.r")
source(paste(prefix$code.plot.ps, "u0-get_case_main.r", sep = ""))

### Load true Phi.
fn.in <- paste(prefix$data, "simu_true_", model, ".rda", sep = "")
if(file.exists(fn.in)){
  load(fn.in)
} else{
  stop(paste(fn.in, " is not found.", sep = ""))
}
Phi <- EPhi

### pre processed phi.Obs.
fn.in <- paste(prefix$data, "pre_process.rda", sep = "")
load(fn.in)

for(i.case in case.names){
  ### subset of mcmc output.
  fn.in <- paste(prefix$subset, i.case, "_PM.rda", sep = "")
  if(!file.exists(fn.in)){
    cat("File not found: ", fn.in, "\n", sep = "")
    next
  }
  load(fn.in)

  ### Subset of mcmc output with scaling.
  fn.in <- paste(prefix$subset, i.case, "_PM_scaling.rda", sep = "")
  if(!file.exists(fn.in)){
    cat("File not found: ", fn.in, "\n", sep = "")
    next
  }
  load(fn.in)

  ### plot posterior mean.
  fn.out <- paste(prefix$plot.ps.single,
                  "prxy_true_wci_", i.case, ".pdf", sep = "")
  pdf(fn.out, width = 5, height = 5)
    ### x-axis: true, y-axis: predicted.
    plotprxy(Phi, phi.PM,
             y.ci = phi.CI,
             weights = 1 / phi.STD.log10,
             xlab = "True Production Rate (log10)",
             ylab = "Predicted Production Rate (log10)",
             main = paste(i.case, " posterior mean", sep = ""))
    mtext(paste(workflow.name, ", ", get.case.main(i.case, model), sep = ""),
          line = 3, cex = 0.6)
    mtext(date(), line = 2.5, cex = 0.4)
  dev.off()

  ### plot posterior median.
  fn.out <- paste(prefix$plot.ps.single,
                  "prxy_true_wci_med_", i.case, ".pdf", sep = "")
  pdf(fn.out, width = 5, height = 5)
    ### x-axis: true, y-axis: predicted.
    plotprxy(Phi, phi.MED,
             y.ci = phi.CI,
             weights = 1 / phi.STD.log10,
             xlab = "True Production Rate (log10)",
             ylab = "Predicted Production Rate (log10)",
             main = paste(i.case, " posterior median", sep = ""))
    mtext(paste(workflow.name, ", ", get.case.main(i.case, model), sep = ""),
          line = 3, cex = 0.6)
    mtext(date(), line = 2.5, cex = 0.4)
  dev.off()

  ### plot posterior log10 mean.
  fn.out <- paste(prefix$plot.ps.single,
                  "prxy_true_wci_log10_", i.case, ".pdf", sep = "")
  pdf(fn.out, width = 5, height = 5)
    ### x-axis: true, y-axis: predicted.
    plotprxy(Phi, 10^(phi.PM.log10),
             y.ci = 10^(phi.CI.log10),
             weights = 1 / phi.STD.log10,
             xlab = "True Production Rate (log10)",
             ylab = "Predicted Production Rate (log10)",
             main = paste(i.case, " posterior log10 mean", sep = ""))
    mtext(paste(workflow.name, ", ", get.case.main(i.case, model), sep = ""),
          line = 3, cex = 0.6)
    mtext(date(), line = 2.5, cex = 0.4)
  dev.off()
}

