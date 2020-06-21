#!/bin/bash

SETTINGS=$1
FILE_DIR=$2

source ${SETTINGS}

# add in new directories to add!
FILE_PATH=${FILE_DIR}/ewas-sum-stats/inhouse-data
echo "preparing inhouse data"
Rscript prep-inhouse-data.r "${FILE_PATH}"

# within inhouse-data/ should deposit a studies.txt files
# and should deposit all the results files in inhouse-data/results/RESULT_NAME
# Then a simple R script can load in studies.txt 
# check that "results_file" column has no missing data
# do some column name checks
# read in cpg annotations
# For each row in studies.txt the script should:
# 1. Do a load of column checks (see other scripts)
# 2. Read in the corresponding results file
# 3. Make a studyID
# 4. Add the studyID to the results file
# 5. Annotate results data
# 6. Make directory ewas-sum-stats/study-data/STUDY-ID
# 7. Write out study data as studies.txt and results data as results.txt