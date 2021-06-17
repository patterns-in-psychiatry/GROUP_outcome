# GROUP_outcome
Creating prediction models for individual outcome of psychosis (GROUP study)

These scripts hasve been used to train and test the outcome prediction models for our study:

"Individualized prediction of three- and six-year outcomes of psychosis in a longitudinal multicenter study: a machine learning approach", by De Nijs et al (in press, NPJ Schizophrenia, June 2021).

We refer to that paper for more detailed information about how these models were built.

These R scripts will train classification models using the support vector machine algorithm. The scripts employ
nested cross-validation with two or three layers:
inner layer: optimization of hyperparameter(s): SVM's cost parameter (C)
middle layer: (optional) recursive feature elimination
outer layer: validation layer
fold sizes are specified within the scripts

There are two flavors of the script: a standard version using all subjects for training and a LSO version
that will perform leave-one-site-out cross-validation.

To run the scripts the following package need to be installed:
film (https://bitbucket.org/RonaldJJ/film/src/master/)
as well as the following R packages:
caret
e1071
RANN
randomForest


Example call:

Rscript3.4.0 /Path/to/Scripts/FeatureSelectionJob.R /Path/to/data/T3/ GcMCn_data GcMCn_runs/NestedCV_T3_GcMCn_FselRun001.RData F

1st argument:	R script to run (including path where the script is)
2nd argument:	location of the data, organized in subdirs (T3 and T6 for our study)
3rd argument:	name of datafile (G: Global functioning, c: classification, M: Model, Cn: Cansas)
4th argument:	name of outputfile (including subdir name and run number)
[two addtional arguments for the LSO script]
5th argument:	resample labels: yes/no (boolean: T/F) (for normal modeling, use: F)

Possible R scripts:
FeatureSelectionJob.R		standard runs on full data set
FeatureSelectionLSOJob.R	Leave-one-site-out runs

Datafile:
TAB-delimited file with N rows (subjects) and M columns (1st column: label (-1 or 1), column 2 - M: features (after scaling)

For the FeatureSelectionLSOJob.R script, two additional arguments must be provided:
(1) name of file with site codes (one column with integers)
(2) site: integer specifying which site should be left out
