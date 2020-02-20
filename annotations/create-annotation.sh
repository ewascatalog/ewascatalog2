#!/bin/bash

FILE_DIR="files"
SRC_DIR="annotations"

Rscript --vanilla ${SRC_DIR}/create-cpg-annotation.r ${FILE_DIR}/cpg-annotation.txt
Rscript --vanilla ${SRC_DIR}/create-gene-annotation.r ${FILE_DIR}/gene-annotation.txt
