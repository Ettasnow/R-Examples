fncCoinTwoSamplePermutationTest <- function(){
  initializeDialog(title=gettextRcmdr("Two/K Sample Permutation Test"))
  variablesFrame <- tkframe(top) #
  groupBox <- variableListBox(variablesFrame, Factors(), title=gettextRcmdr("Groups\n(select one)"))
  responseBox <- variableListBox(variablesFrame, Numeric(), title=gettextRcmdr("Response Variable\n(select one)"))
  blockBox <- variableListBox(variablesFrame, Factors(), title="Block\n(select none or one)") #
  onOK <- function(){
    group <- getSelection(groupBox)
    if (length(group) == 0) {
      errorCondition(recall=fncCoinTwoSamplePermutationTest, message=gettextRcmdr("You must select a groups variable."))
      return()
    }
    response <- getSelection(responseBox)
    if (length(response) == 0) {
      errorCondition(recall=fncCoinTwoSamplePermutationTest, message=gettextRcmdr("You must select a response variable."))
      return()
    }
    block <- getSelection(blockBox) #
    if (length(block) > 0) {
      if (block == group) {
        errorCondition(recall=fncCoinTwoSamplePermutationTest, message=gettextRcmdr("The group and block variables must be different."))
        return()
      }
      block = paste(" | ", block, " ", sep="") #
    } else {
      block = "" #
    }
    alternative <- as.character(tclvalue(alternativeVariable))
    test <- as.character(tclvalue(testVariable)) #
    subset <- tclvalue(subsetVariable) #
    subset <- if (trim.blanks(subset) == gettextRcmdr("<all valid cases>")) "" else paste(", subset=", subset, sep="") #
    closeDialog()
    .activeDataSet <- ActiveDataSet()
    doItAndPrint(paste("tapply(", paste(.activeDataSet,"$", response, sep=""),
                       ", ", paste(.activeDataSet,"$", group, sep=""), ", median, na.rm=TRUE)", sep=""))
    #        if (ties == "default") {
    strTies = ""
    #        } else {
    #            strTies = paste(", ties.method='", ties, "' ", sep="")
    #        }
    if (test == "default"){
      doItAndPrint(paste("oneway_test(", response, " ~ ", group, block, ", alternative='", 
                         alternative, "'", strTies, ", data=", .activeDataSet, subset, ")", sep=""))
    }
    else doItAndPrint(paste("oneway_test(", response, " ~ ", group, block, ", alternative='", 
                            alternative, "'", strTies, ", distribution='", test, "', data=", .activeDataSet, subset, ")", sep=""))
    tkfocus(CommanderWindow())
  }
  OKCancelHelp(helpSubject="oneway_test")
  optionsFrame <- tkframe(top) #
  radioButtons(optionsFrame, name="alternative", buttons=c("twosided", "less", "greater"), values=c("two.sided", "less", "greater"),
               labels=gettextRcmdr(c("Two-sided", "Difference < 0", "Difference > 0")), title=gettextRcmdr("Alternative Hypothesis"))
  
  radioButtons(optionsFrame, name="test", buttons=c("default", "exact", "approximate", "asymptotic"), 
               labels=gettextRcmdr(c("Default", "Exact", "Monte Carlo resampling approximation", "Asymptotic null distribution")), 
               title=gettextRcmdr("Type of Test"))
  
  #tiesFrame <- tkframe(top) #
  #radioButtons(tiesFrame, name="ties", buttons=c("default", "mid-ranks", "average-scores"), 
  #    labels=c("Default", "Mid ranks", "Average scores"), 
  #    title="Method for ties") # To add translation !!!
  
  subsetBox() #
  
  tkgrid(getFrame(groupBox), labelRcmdr(variablesFrame, text="    "), getFrame(responseBox), getFrame(blockBox), sticky="nw") # 
  tkgrid(variablesFrame, sticky="nw") #
  groupsLabel(groupsBox=groupBox) #
  tkgrid(alternativeFrame, labelRcmdr(optionsFrame, text="    "), labelRcmdr(optionsFrame, text="    "), testFrame, sticky="nw") #
  tkgrid(optionsFrame, sticky="nw") #
  #tkgrid(tiesFrame, sticky="w") #
  tkgrid(subsetFrame, sticky="w") #
  tkgrid(buttonsFrame, sticky="w") #
  dialogSuffix(rows=5, columns=1) #
  #tkgrid(getFrame(groupBox), getFrame(responseBox), sticky="nw")
  #groupsLabel(groupsBox=groupBox, columnspan=2)
  #tkgrid(alternativeFrame, testFrame, sticky="nw")
  #tkgrid(buttonsFrame, columnspan=2, sticky="w")
  #dialogSuffix(rows=4, columns=2)
}