################################################################################
#' Run an experiment using \code{\link{spades}}
#'
#' This is essentially a wrapper around the \code{spades} call that allows for multiple
#' calls to spades. This function will use a single processor, or multiple processors if
#' \code{\link[raster]{beginCluster}} has been run first.
#'
#' Generally, there are 2 reasons to do this: replication and varying simulation inputs
#' to accomplish some sort of simulation experiment. This function deals with both of these
#' cases. In the case of varying inputs, this function will attempt to create a fully
#' factorial experiment among all levels of the variables passed into the function.
#' If all combinations do not make sense, e.g., if parameters and modules are varied,
#' and some of the parameters don't exist in all combinations of modules, then the function
#' will do an "all meaningful combinations" factorial experiment. Likewise, fully factorial
#' combinations of parameters and inputs may not be the desired behaviour. The function
#' requires a \code{simList} object, acting as the basis for the experiment,
#' plus optional inputs and/or objects and/or params and/or modules and/or replications.
#'
#' @inheritParams spades
#'
#' @param inputs Like for \code{\link{simInit}}, but a list of \code{inputs} data.frames.
#'               See details and examples.
#' @param objects Like for \code{\link{simInit}}, but a list of named lists of named objects.
#'               See details and examples.
#' @param params Like for \code{\link{simInit}}, but for each parameter, provide a list of
#'               alternative values. See details and examples.
#' @param modules Like for \code{\link{simInit}}, but a list of \code{module} names (as strings).
#'                See details and examples.
#' @param replicates The number of replicates to run of the same \code{simList}.
#'                   See details and examples.
#'
#' @param substrLength Numeric. While making \code{outputPath} for each spades call, this
#'                     is the number of characters kept from each factor level.
#'                     See details and examples.
#'
#' @param dirPrefix String vector. This will be concatenated as a prefix on the
#'                  directory names. See details and examples.
#'
#' @param saveExperiment Logical. Should params, modules, inputs, sim, and resulting
#' experimental design be saved to a file. If TRUE are saved to a single list
#' called \code{experiment}. Default TRUE.
#'
#' @param experimentFile String. Filename if \code{saveExperiment} is TRUE; saved to
#' \code{outputPath(sim)} in \code{.RData} format. See Details.
#'
#' @param clearSimEnv Logical. If TRUE, then the envir(sim) of each simList in the return list
#'                    is emptied. This is to reduce RAM load of large return object.
#'                    Default FALSE.
#'
#' @param ... Passed to \code{spades}. Specifically, \code{debug}, \code{.plotInitialTime}, or
#'            \code{.saveInitialTime}.
#'
#' @details
#' This function requires a complete simList: this simList will form the basis of the
#' modifications as passed by params, modules, inputs, and objects.
#' All params, modules, inputs or objects
#' passed into this function will override the corresponding params, modules, inputs,
#' or identically named objects that are in the \code{sim} argument.
#'
#' This function is parallel aware, using the same mechanism as used in the \code{raster}
#' package. Specifically, if you start a cluster using \code{\link{beginCluster}}, then
#' this experiment function will automatically use that cluster. It is always a good
#' idea to stop the cluster when finished, using \code{\link{endCluster}}. See
#'
#' Here are generic examples of how \code{params}, \code{modules}, \code{objects},
#' and \code{inputs} should be structured.
#'
#'   \code{params = list(moduleName = list(paramName = list(val1, val2)))}.
#'
#'   \code{modules = list(c("module1","module2"), c("module1","module3"))}
#'
#'   \code{objects = list(objName = list(object1=object1, object2=object2))}
#'
#'   \code{inputs = list(
#'         data.frame(file = pathToFile1, loadTime = 0, objectName = "landscape",
#'                    stringsAsFactors = FALSE),
#'         data.frame(file = pathToFile2, loadTime = 0, objectName = "landscape",
#'                    stringsAsFactors = FALSE)
#'   )}
#'
#'
#' Output directories are changed using this function: this is one of the dominant
#' side effects of this function. If there are only replications, then a set of
#' subdirectories will be created, one for each replicate.
#' If there are varying parameters and or modules, \code{outputPath} is updated to include
#' a subdirectory for each level of the experiment. These are not nested, i.e., even if there
#' are nested factors, all subdirectories due to the experimental setup will be
#' at the same level. Replicates will be one level below this.
#' The subdirectory names will include the module(s), parameter names, the parameter values,
#' and input index number (i.e., which row of the inputs data.frame).
#' The default rule for naming is a concatenation of:
#'
#' 1. The experiment level (arbitrarily starting at 1). This is padded with zeros if there are
#' many experiment levels.
#'
#' 2. The module, parameter name and parameter experiment level (not the parameter value,
#' as values could be complex), for each parameter that is varying.
#'
#' 3. The module set.
#'
#' 4. The input index number
#'
#' 5. Individual identifiers are separated by a dash.
#'
#' 6. Module - Parameter - Parameter index triplets are separated by underscore.
#'
#' e.g., a folder called: \code{01-fir_spr_1-car_N_1-inp_1} would be the first
#' experiment level (01), the first parameter value for the spr* parameter of
#' the fir* module, the first parameter value of the N parameter of the
#' car* module, and the first input dataset provided.
#'
#' This subdirectory name could be long if there are many dimensions to the experiment.
#' The parameter \code{substrLength}  determines the level of truncation of the
#' parameter, module and input names for  these subdirectories.
#' For example, the  resulting directory name for changes to the \code{spreadprob}
#' parameter in the \code{fireSpread} module and the \code{N} parameter in the
#' \code{caribouMovement} module  would be:
#' \code{1_fir_spr_1-car_N_1} if \code{substrLength} is 3, the default.
#'
#' Replication is treated slightly differently. \code{outputPath} is always 1 level below the
#' experiment level for a replicate.
#' If the call to \code{experiment} is not a factorial experiment (i.e., it is just
#' replication), then the
#' default is to put the replicate subdirectories at the top level of \code{outputPath}.
#' To force this one level down, \code{dirPrefix} can be used or a manual change to
#' \code{outputPath} before the call to experiment.
#'
#' \code{dirPrefix} can be used to give custom names to directories for outputs.
#' There is a special value, \code{"simNum"}, that is used as default, which is an arbitrary
#' number  associated with the experiment.
#' This corresponds to the row number in the \code{attr(sims, "experiment")}.
#' This \code{"simNum"} can be used with other strings, such as
#' \code{dirPrefix = c("expt","simNum")}.
#'
#' The experiment structure is kept in two places: the return object has an attribute, and a file
#' named \code{experiment.RData} (see argument \code{experimentFile}) located in \code{outputPath(sim)}.
#'
#' \code{substrLength}, if \code{0}, will eliminate the subfolder naming convention and use
#' only \code{dirPrefix}.
#'
#' @return Invisibly returns a list of the resulting \code{simList} objects from the fully
#' factorial experiment. This list has an attribute, which a list with 2 elements:
#' the experimental design provided in a wide data.frame and the experiment values
#' in a long data.frame. There is also a file saved with these two data.frames.
#' It is named whatever is passed into \code{experimentFile}.
#' Since returned list of \code{simList} objects may be large, the user is not obliged to
#' return this object (as it is returned invisibly).
#' Clearly, there may be objects saved during simulations. This would be determined as per a
#' normal \code{\link{spades}} call, using \code{outputs} like, say, \code{outputs(sims[[1]])}.
#'
#' @seealso \code{\link{simInit}}, \code{\link{SpaDES}}
#'
#' @importFrom raster getCluster returnCluster
#' @importFrom parallel clusterApplyLB clusterEvalQ
#' @export
#' @docType methods
#' @rdname experiment
#'
#' @author Eliot McIntire
#'
#' @examples
#' \dontrun{
#'  library(magrittr) # use %>% in a few examples
#'
#'  tmpdir <- file.path(tempdir(), "examples")
#'
#' # Create a default simList object for use through these examples
#'   mySim <- simInit(
#'     times = list(start = 0.0, end = 2.0, timeunit = "year"),
#'     params = list(
#'       .globals = list(stackName = "landscape", burnStats = "nPixelsBurned"),
#'       # Turn off interactive plotting
#'       fireSpread = list(.plotInitialTime = NA),
#'       caribouMovement = list(.plotInitialTime = NA),
#'       randomLandscapes = list(.plotInitialTime = NA)
#'     ),
#'     modules = list("randomLandscapes", "fireSpread", "caribouMovement"),
#'     paths = list(modulePath = system.file("sampleModules", package = "SpaDES"),
#'                  outputPath = tmpdir),
#'     # Save final state of landscape and caribou
#'     outputs = data.frame(objectName = c("landscape", "caribou"), stringsAsFactors = FALSE)
#'   )
#'
#' # Example 1 - test alternative parameter values
#'   # Create an experiment - here, 2 x 2 x 2 (2 levels of 2 params in fireSpread,
#'   #    and 2 levels of 1 param in caribouMovement)
#'
#'   # Here is a list of alternative values for each parameter. They are length one
#'   #   numerics here -- e.g., list(0.2, 0.23) for spreadprob in fireSpread module,
#'   #   but they can be anything, as long as it is a list.
#'   experimentParams <- list(fireSpread = list(spreadprob = list(0.2, 0.23),
#'                                              nFires = list(20, 10)),
#'                             caribouMovement = list(N = list(100, 1000)))
#'
#'   sims <- experiment(mySim, params = experimentParams)
#'
#'   # see experiment:
#'   attr(sims, "experiment")
#'
#'   # Read in outputs from sims object
#'   FireMaps <- do.call(stack, lapply(1:NROW(attr(sims, "experiment")$expDesign),
#'                      function(x) sims[[x]]$landscape$Fires))
#'   Plot(FireMaps, new = TRUE)
#'
#'   # Or reload objects from files, useful if sim objects too large to store in RAM
#'   caribouMaps <- lapply(sims, function(sim) {
#'     caribou <- readRDS(outputs(sim)$file[outputs(sim)$objectName == "caribou"])
#'     })
#'   names(caribouMaps) <- paste0("caribou",1:8)
#'   # Plot does not plot whole lists (yet)
#'   for(i in 1:NROW(attr(sims,"experiment")$expDesign)){
#'     Plot(caribouMaps[[i]], size = 0.1)}
#'
#' # Example 2 - test alternative modules
#'   # Example of changing modules, i.e., caribou with and without fires
#'   # Create an experiment - here, 2 x 2 x 2 (2 levels of 2 params in fireSpread,
#'   #    and 2 levels of 1 param in caribouMovement)
#'   experimentModules <- list(
#'       c("randomLandscapes", "fireSpread", "caribouMovement"),
#'       c("randomLandscapes", "caribouMovement"))
#'   sims <- experiment(mySim, modules = experimentModules)
#'   attr(sims, "experiment")$expVals # shows 2 alternative experiment levels
#'
#' # Example 3 - test alternative parameter values and modules
#'   # Note, this isn't fully factorial because all parameters are not
#'   #   defined inside smaller module list
#'   sims <- experiment(mySim, modules = experimentModules, params = experimentParams)
#'   attr(sims, "experiment")$expVals # shows 10 alternative experiment levels
#'
#' # Example 4 - manipulate manipulate directory names -
#'   #  "simNum" is special value for dirPrefix, it is converted to 1, 2, ...
#'   sims <- experiment(mySim, params = experimentParams, dirPrefix = c("expt", "simNum"))
#'   attr(sims, "experiment")$expVals # shows 10 alternative experiment levels, 26 unique
#'                                    #   parameter values
#'
#' # Example 5 - doing replicate runs -
#'   sims <- experiment(mySim, replicates = 2)
#'   attr(sims, "experiment")$expDesign # shows 2 replicates of same experiment
#'
#' # Example 6 - doing replicate runs, but within a sub-directory
#'   sims <- experiment(mySim, replicates = 2, dirPrefix = c("expt"))
#'   lapply(sims, outputPath) # shows 2 replicates of same experiment, within a sub directory
#'
#' # Example 7 - doing replicate runs, of a complex, non factorial experiment.
#'   # Here we do replication, parameter variation, and module variation all together.
#'   # This creates 20 combinations.
#'   # The experiment function tries to make fully factorial, but won't
#'   # if all the levels don't make sense. Here, changing parameter values
#'   # in the fireSpread module won't affect the simulation when the fireSpread
#'   # module is not loaded:
#'   # library(raster)
#'   # beginCluster(20) # if you have multiple clusters available, use them here to save time
#'   sims <- experiment(mySim, replicates = 2, params = experimentParams,
#'                     modules = experimentModules,
#'                     dirPrefix = c("expt", "simNum"))
#'   # endCluster() # end the clusters
#'   attr(sims, "experiment")
#'
#' # Example 8 - Use replication to build a probability map.
#'   # For this to be meaningful, we need to provide a fixed input landscape,
#'   #   not a randomLandscape for each experiment level. So requires 2 steps.
#'   # Step 1 - run randomLandscapes module twice to get 2 randomly
#'   #  generated landscape maps. We will use 1 right away, and we will
#'   #  use the two further below
#'   mySimRL <- simInit(
#'      times = list(start = 0.0, end = 0.1, timeunit = "year"),
#'      params = list(
#'        .globals = list(stackName = "landscape"),
#'        # Turn off interactive plotting
#'        randomLandscapes = list(.plotInitialTime = NA)
#'      ),
#'      modules = list("randomLandscapes"),
#'      paths = list(modulePath = system.file("sampleModules", package = "SpaDES"),
#'                   outputPath = file.path(tmpdir, "landscapeMaps1")),
#'      outputs = data.frame(objectName = "landscape", saveTime = 0, stringsAsFactors = FALSE)
#'   )
#'   # Run it twice to get two copies of the randomly generated landscape
#'   mySimRLOut <- experiment(mySimRL, replicate = 2)
#'
#'   #extract one of the random landscapes, which will be passed into next as an object
#'   landscape <- mySimRLOut[[1]]$landscape
#'
#'   # here we don't run the randomLandscapes module; instead we pass in a landscape
#'   #  as an object, i.e., a fixed input
#'   mySimNoRL <- simInit(
#'      times = list(start = 0.0, end = 1, timeunit = "year"), # only 1 year to save time
#'      params = list(
#'        .globals = list(stackName = "landscape", burnStats = "nPixelsBurned"),
#'        # Turn off interactive plotting
#'        fireSpread = list(.plotInitialTime = NA),
#'        caribouMovement = list(.plotInitialTime = NA)
#'      ),
#'      modules = list("fireSpread", "caribouMovement"), # No randomLandscapes modules
#'      paths = list(modulePath = system.file("sampleModules", package = "SpaDES"),
#'                   outputPath = tmpdir),
#'      objects = c("landscape"), # Pass in the object here
#'      # Save final state (the default if saveTime is not specified) of landscape and caribou
#'      outputs = data.frame(objectName = c("landscape", "caribou"), stringsAsFactors = FALSE)
#'   )
#'
#'   # Put outputs into a specific folder to keep them easy to find
#'   outputPath(mySimNoRL) <- file.path(tmpdir, "example8")
#'   sims <- experiment(mySimNoRL, replicates = 8) # Run experiment
#'   attr(sims, "experiment") # shows the experiment, which in this case is just replicates
#'
#'   # list all files that were saved called 'landscape'
#'   landscapeFiles <- dir(outputPath(mySimNoRL), recursive = TRUE, pattern = "landscape",
#'                         full.names = TRUE)
#'
#'   # Can read in Fires layers from disk since they were saved, or from the sims
#'   #  object
#'   # Fires <- lapply(sims, function(x) x$landscape$Fires) %>% stack
#'   Fires <- lapply(landscapeFiles, function(x) readRDS(x)$Fires) %>% stack
#'   Fires[Fires > 0] <- 1 # convert to 1s and 0s
#'   fireProb <- sum(Fires)/nlayers(Fires) # sum them and convert to probability
#'   Plot(fireProb, new = TRUE)
#'
#' # Example 9 - Pass in inputs, i.e., input data objects taken from disk
#'   #  Here, we, again, don't provide randomLandscapes module, so we need to
#'   #  provide an input stack called lanscape. We point to the 2 that we have
#'   #  saved to disk in Example 8
#'   mySimInputs <- simInit(
#'      times = list(start = 0.0, end = 2.0, timeunit = "year"),
#'      params = list(
#'        .globals = list(stackName = "landscape", burnStats = "nPixelsBurned"),
#'        # Turn off interactive plotting
#'        fireSpread = list(.plotInitialTime = NA),
#'        caribouMovement = list(.plotInitialTime = NA)
#'      ),
#'      modules = list("fireSpread", "caribouMovement"),
#'      paths = list(modulePath = system.file("sampleModules", package = "SpaDES"),
#'                   outputPath = tmpdir),
#'      # Save final state of landscape and caribou
#'      outputs = data.frame(objectName = c("landscape", "caribou"), stringsAsFactors = FALSE)
#'   )
#'   landscapeFiles <- dir(tmpdir, pattern = "landscape_year0", recursive = TRUE, full.names = TRUE)
#'
#'   # Varying inputs files - This could be combined with params, modules, replicates also
#'   outputPath(mySimInputs) <- file.path(tmpdir, "example9")
#'   sims <- experiment(mySimInputs,
#'      inputs = lapply(landscapeFiles,function(filenames) {
#'        data.frame(file = filenames, loadTime = 0, objectName = "landscape",
#'                   stringsAsFactors = FALSE) })
#'    )
#'
#'   # load in experimental design object
#'   experiment <- load(file = file.path(tmpdir, "example9", "experiment.RData")) %>% get()
#'   print(experiment) # shows input files and details
#'
#' # Example 10 - Use a very simple output dir name using substrLength = 0,
#'   #   i.e., just the simNum is used for outputPath of each spades call
#'   outputPath(mySim) <- file.path(tmpdir, "example10")
#'   sims <- experiment(mySim, modules = experimentModules, replicates = 2,
#'                      substrLength = 0)
#'   lapply(sims, outputPath) # shows that the path is just the simNum
#'   experiment <- load(file = file.path(tmpdir, "example10", "experiment.RData")) %>% get()
#'   print(experiment) # shows input files and details
#'
#' # Example 11 - use clearSimEnv = TRUE to remove objects from simList
#'   # This will shrink size of return object, which may be useful because the
#'   #  return from experiment function may be a large object (it is a list of
#'   # simLists). To see size of a simList, you have to look at the objects
#'   #  contained in the  envir(simList).  These can be obtained via objs(sim)
#'   sapply(sims, function(x) object.size(objs(x))) %>% sum + object.size(sims)
#'   # around 3 MB
#'   # rerun with clearSimEnv = TRUE
#'   sims <- experiment(mySim, modules = experimentModules, replicates = 2, substrLength = 0,
#'                      clearSimEnv = TRUE)
#'   sapply(sims, function(x) object.size(objs(x))) %>% sum + object.size(sims)
#'   # around 250 kB, i.e., all the simList contents except the objects.
#'
#' # Example 12 - pass in objects
#'   experimentObj <- list(landscape = lapply(landscapeFiles, readRDS) %>%
#'                                     setNames(paste0("landscape",1:2)))
#'   # Pass in this list of landscape objects
#'   sims <- experiment(mySimNoRL, objects = experimentObj)
#'
#' # Remove all temp files
#'   unlink(tmpdir, recursive = TRUE)
#' }
#'
setGeneric(
  "experiment",
  function(sim, replicates = 1, params, modules, objects = list(), inputs,
           dirPrefix = "simNum", substrLength = 3, saveExperiment = TRUE,
           experimentFile = "experiment.RData", clearSimEnv = FALSE, ...) {
  standardGeneric("experiment")
})

#' @rdname experiment
setMethod(
  "experiment",
  signature(sim = "simList"),
  definition = function(sim, replicates, params, modules, objects, inputs,
                        dirPrefix, substrLength, saveExperiment,
                        experimentFile, clearSimEnv, ...) {

    if (missing(params)) params <- list()
    if (missing(modules)) modules <- list(unlist(SpaDES::modules(sim)[-(1:4)]))
    if (missing(inputs)) inputs <- list()
    if (missing(objects)) {objects <- list() } else if (length(objects) == 1) {
      objects <- unlist(objects, recursive = FALSE)
    }

    cl <- tryCatch(getCluster(), error = function(x) NULL)
    on.exit(if (!is.null(cl)) returnCluster())

    #if (length(modules) == 0) modules <- list(modules(sim)[-(1:4)])
    factorialExpList <- lapply(seq_along(modules), function(x) {
      paramsTmp <- pmatch(modules[[x]], names(params)) %>% na.omit
      factorsTmp <- if (NROW(paramsTmp) > 0) {
        # unlist(params[paramsTmp], recursive = FALSE)
        lapply(params[paramsTmp], function(z) {
          lapply(z, function(y) { seq_along(y) })
        }) %>% unlist(recursive = FALSE)
      } else {
        params
      }

      if (length(inputs) > 0) {
        inputsList <- list(input = seq_len(NROW(inputs)))
        factorsTmp <- append(factorsTmp, inputsList)
      }
      if (length(objects) > 0) {
        objectsList <- list(object = seq_along(objects))
        factorsTmp <- append(factorsTmp, objectsList)
      }

      factorialExpInner <- expand.grid(factorsTmp, stringsAsFactors = FALSE)

      modulesShort <- paste(modules[[x]],collapse = ",")
      if (NROW(factorialExpInner) > 0 ) {
        if (any(!(names(factorialExpInner) %in% c("object", "input")))) {
          factorialExpInner[["modules"]] <- x
        }
      } else {
        factorialExpInner <- data.frame(modules = x, stringsAsFactors = FALSE)
      }
      factorialExpInner
    })
    factorialExp <- rbindlist(factorialExpList, fill = TRUE) %>%
      data.frame(stringsAsFactors = FALSE)
    numExpLevels <- NROW(factorialExp)
    factorialExp$expLevel <- seq_len(numExpLevels)

    # Add replicates to experiment
    if (replicates > 1) {
      if (length(replicates == 1)) {
        replicates = seq_len(replicates)
      }
      factorialExp <- do.call(rbind, replicate(length(replicates), factorialExp,
                                               simplify = FALSE))
      factorialExp$replicate = rep(replicates, each = numExpLevels)
    }

    FunDef <- function(ind, ...) {
      mod <- strsplit(names(factorialExp), split = "\\.") %>%
        sapply(function(x) x[1])
      param <- strsplit(names(factorialExp), split = "\\.") %>%
        sapply(function(x) x[2])
      param[is.na(param)] <- ""

      paramValues <- factorialExp[ind,]

      whNotExpLevel <- which(colnames(paramValues) != "expLevel")
      if (length(whNotExpLevel) < length(paramValues)) {
        mod <- mod[whNotExpLevel]
        param <- param[whNotExpLevel]
        paramValues <- paramValues[whNotExpLevel]
      }

      whNotRepl <- which(colnames(paramValues) != "replicate")
      if (length(whNotRepl) < length(paramValues)) {
        repl <- paramValues$replicate
        mod <- mod[whNotRepl]
        param <- param[whNotRepl]
        paramValues <- paramValues[whNotRepl]
      }

      notNA <- which(!is.na(paramValues))

      if (length(notNA) < length(mod)) {
        mod <- mod[notNA]
        param <- param[notNA]
        paramValues <- paramValues[notNA]
      }

      sim_ <- copy(sim)
      experimentDF <- data.frame(module = character(0),
                                 param = character(0),
                                 val = I(list()),
                                 modules = character(0),
                                 input = data.frame(),
                                 object = character(0),
                                 expLevel = numeric(0),
                                 stringsAsFactors = FALSE)

      for (x in seq_along(mod)) {
        if (any(mod != "modules")) {
          y <- factorialExp[ind, names(paramValues)[x]]

          if (!is.na(y) & (mod[x] != "modules")) {
            val <- params[[mod[x]]][[param[[x]]]][[y]]
            params(sim_)[[mod[x]]][[param[[x]]]] <- val #factorialExp[ind,x]
            experimentDF <- rbindlist(
              l = list(
                experimentDF,
                data.frame(
                  module = if (!(mod[x] %in% c("input", "object"))) mod[x] else NA,
                  param = if (!(mod[x] %in% c("input", "object"))) param[x] else NA,
                  val = if (!(mod[x] %in% c("input", "object"))) I(list(val)) else list(NA),
                  modules = paste0(unlist(modules[factorialExp[ind, "modules"]]), collapse = ","),
                  input = if ((mod[x] %in% c("input"))) inputs[[factorialExp[ind, "input"]]] else NA,
                  object = if ((mod[x] %in% c("object"))) names(objects)[[factorialExp[ind, "object"]]] else NA,
                  expLevel = factorialExp[ind, "expLevel"],
                  stringsAsFactors = FALSE
              )),
              use.names = TRUE,
              fill = TRUE)
          }
        } else {
          experimentDF <- rbindlist(
            l = list(
              experimentDF,
              data.frame(modules = paste0(unlist(modules[factorialExp[ind, "modules"]]), collapse = ","),
                         expLevel = factorialExp[ind,"expLevel"],
                         stringsAsFactors = FALSE
            )),
            use.names = TRUE,
            fill = TRUE)
        }

        if ("modules" %in% names(factorialExp)) {
          if (!identical(sort(unlist(modules[factorialExp[ind, "modules"]])),
                         sort(unlist(SpaDES::modules(sim)[-(1:4)])))) { # test if modules are different from sim,
            #  if yes, rerun simInit
            sim_ <- simInit(params = params(sim_),
                            modules = as.list(unlist(modules[factorialExp[ind, "modules"]])),
                            times = append(lapply(times(sim_)[2:3], as.numeric), times(sim_)[4]),
                            paths = paths(sim_),
                            outputs = outputs(sim_))

          }
        }
      }

      # Deal with directory structures
      if (any(dirPrefix == "simNum")) {
        exptNum <- paddedFloatToChar(factorialExp$expLevel[ind],
                                     ceiling(log10(numExpLevels + 1)))
      }
      dirPrefixTmp <- paste0(dirPrefix, collapse = "")

      if ((numExpLevels > 1) & (substrLength > 0)) {
        dirName <- paste(collapse = "-", substr(mod, 1, substrLength),
                         substr(param, 1, substrLength),
                         paramValues, sep = "_")
        dirName <- gsub(dirName, pattern = "__", replacement = "_")
        if (any(dirPrefix == "simNum")) {
          dirPrefix <- gsub(dirPrefixTmp, pattern = "simNum", replacement = exptNum)
        }
        if (any(dirPrefix != "")) {
          dirName <- paste(paste(dirPrefix, collapse = ""), dirName, sep = "_")
        }
      } else if (substrLength == 0) {
        if (any(dirPrefix != "")) {
          simplePrefix <- if (any(dirPrefix == "simNum")) exptNum else ""
          dirName <- gsub(dirPrefixTmp, pattern = "simNum", replacement = simplePrefix)
        }
      } else {
        if (any(dirPrefix != "")) {
          dirName <- gsub(dirPrefixTmp, pattern = "simNum", replacement = "")
        }
      }

      if (exists("repl", inherits = FALSE)) {
        nn <- paste0("rep", paddedFloatToChar(repl, ceiling(log10(length(replicates) + 1))))
        dirName <- if (!is.null(dirName)) {
          file.path(dirName, nn)
        } else {
          file.path(nn)
        }
      }
      newOutputPath <- file.path(paths(sim_)$outputPath, dirName) %>%
        gsub(pattern = "/$", replacement = "") %>% gsub(pattern = "//", replacement = "/")
      if (!dir.exists(newOutputPath)) dir.create(newOutputPath, recursive = TRUE)
      paths(sim_)$outputPath <- newOutputPath
      if (NROW(outputs(sim_))) {
        outputs(sim_)$file <- file.path(newOutputPath, basename(outputs(sim_)$file))
      }
      # Actually put inputs into simList
      if (length(inputs) > 0) {
        SpaDES::inputs(sim_) <- inputs[[factorialExp[ind, "input"]]]
      }
      # Actually put objects into simList
      if (length(objects) > 0) {
        replaceObjName <- strsplit(names(objects)[[factorialExp[ind, "object"]]],
                                   split = "\\.")[[1]][1]
        sim_[[replaceObjName]] <- objects[[factorialExp[ind, "object"]]]
      }
      sim3 <- spades(sim_, ...)
      return(list(sim3, experimentDF))
    }

    if (!is.null(cl)) {
      parFun <- "clusterApplyLB"
      args <- list(x = 1:NROW(factorialExp), fun = FunDef)
      args <- append(list(cl = cl), args)
      if (!is.na(pmatch("Windows", Sys.getenv("OS")))) {
        parallel::clusterEvalQ(cl, library(SpaDES))
      }
    } else {
      parFun <- "lapply"
      args <- list(X = 1:NROW(factorialExp), FUN = FunDef)
    }

    expOut <- do.call(get(parFun), args)
    sims <- lapply(expOut, function(x) x[[1]])
    expDFs <- lapply(expOut, function(x) x[[2]])
    experimentDF <- rbindlist(expDFs, fill = TRUE, use.names = TRUE) %>%
      data.frame(stringsAsFactors = FALSE)

    keepCols <- names(experimentDF) %in% c(names(factorialExp),
                                           "param"[length(params) > 1],
                                           "module"[length(params) > 1],
                                           "modules"[length(modules) > 1],
                                           "val"[length(params) > 1])

    experimentDF <- experimentDF[,keepCols]


    experiment <- list(expDesign = factorialExp, expVals = experimentDF)

    # Factorial Levels are determined at this point. Save file.
    if (saveExperiment) {
      save(experiment, file = file.path(outputPath(sim), experimentFile))
    }
    attr(sims, "experiment") <- experiment
    if (clearSimEnv) {sims <- lapply(sims, function(x) {
      rm(list = ls(envir(x)), envir = envir(x))
      x
    })
    }
    return(invisible(sims))
  })
