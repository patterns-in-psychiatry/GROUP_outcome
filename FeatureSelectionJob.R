#!/usr/bin/env Rscript
argin = commandArgs(trailingOnly=TRUE)

wd = argin[1]
fin = argin[2]
fout = argin[3]
resamp = argin[4]

cat(sprintf("Working directory: %s\nInput file: %s\nOutput file: %s\nResampling run: %s",wd,fin,fout,resamp))

library("film")
library("e1071")
library("caret")
library("RANN")
library("randomForest")

#############################################################################

setwd(wd)

Fmat <- read.delim(fin,header = F)

# First column is the target vector
Tvec <- Fmat[,1]
if (all(abs(Tvec)==1)){
  cat("\n\nClassification: setting metric to Kappa")
  Tvec = as.factor(Tvec)
  metric = "Kappa"
  maximize = T
} else {
  cat("\n\nRegression: setting metric to RMSE")
  metric = "RMSE"
  maximize = F
}

if (resamp=="T"){
  Tvec = sample(Tvec,size = length(Tvec))
} 

Fmat <- Fmat[,-1]
Nf <- ncol(Fmat)

#############################################################################

Kouter <- 10
Kmid <- 10 # <- cross validation in case of rfe feature selection
Kinner <- 10
InnerRepeats <- 1

innerCVsetup <- trainControl(method = "repeatedcv"
                             ,number = Kinner
                             ,repeats = InnerRepeats
                             ,allowParallel = F
)
tuneGrid <- data.frame(cost = sqrt(2)^(-12:-2))
svmCall = getModelInfo("svmLinear2")[[1]]

# The following redefines the call to e1071::svm to always compute class weights.
# This means that the weights will vary (slightly) over folds in EACH CV layer.
# Using this is incompatible with providing class weights to train or train.nested,
# using both with likely result in an error.
#
svmCall$fit = function(x, y, wts, param, lev, last, classProbs, ...) {
                    classWeights = as.numeric(table(y))
                    classWeights = max(classWeights)/classWeights
		    classWeights <- c(1, 1)
                    names(classWeights) = levels(y)
                    if(any(names(list(...)) == "probability") | is.numeric(y))
                    {
                      out <- e1071::svm(x = as.matrix(x), y = y,
                                        kernel = "linear",
                                        cost = param$cost,
                                        class.weights =	classWeights,                                        
                                        ...)
                    } else {
                      out <- e1071::svm(x = as.matrix(x), y = y,
                                        kernel = "linear",
                                        cost = param$cost,
                                        probability = classProbs,
                                        class.weights = classWeights,
                                        ...)
                    }

                    out
                  }

# You can also fix the class weights, if you do, make sure you do the following:
# - comment out lines 63-85
# - define the class weights in some variable (see example below)
# - add this variable to the call to trainNested as a named argument
#   with the name "class.weights" (see the help entry for e1071::svm)
#
# Example class weights variable definition (largest class has weight of 1)
#  classWeights <- as.numeric(table(Tvec))
#  classWeights <-max(classWeights)/classWeights
#  names(classWeights) = levels(Tvec)

#############################################################################

FselSetup <- makeFselSetup("rfe")
FselSetup$sizes <- 1:Nf
FselSetup$control$number <- Kmid
FselSetup$control$holdout = 0
FselSetup$control$metric = c(internal = metric, external = metric)
FselSetup$control$maximize = c(internal = maximize,external = maximize)

FselSetup$control$saveDetails = T
FselSetup$control$returnResamp = "all"
FselSetup$contros$functions$selectSize = function(x, metric, tol = 10, maximize) 
{
  if (!maximize) {
    best <- min(x[, metric])
    perf <- (x[, metric] - best)/best * 100
    flag <- perf <= tol
  }
  else {
    best <- max(x[, metric])
    perf <- (best - x[, metric])/best * 100
    flag <- perf <= tol
  }
  min(x[flag, "Variables"])
}
FselSetup$control$verbose <- F
FselSetup$control$allowParallel <- F

#############################################################################

M <- trainNested(Fmat, Tvec, K = Kouter, V = TRUE, FselSetup = FselSetup, SaveFolds = T, ModelSelect = NULL,  # options for trainNested
                 method = svmCall,trControl = innerCVsetup,tuneGrid = tuneGrid,
                 metric = metric,scale = F,differences = F)    # options for the train function

save(M,file = fout)


