#!/bin/bash

FILE_DIR=$1

# put the data in the database
while read id; do
	echo "$id"

	# Create zenodo doi
	python3 zenodo.py ${id} ${FILE_DIR}

done <${FILE_DIR}/ewas-sum-stats/studies-to-add.txt