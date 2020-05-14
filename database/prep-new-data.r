# ----------------------------------------------------
# Sort new ewas data for input into catalog
# ----------------------------------------------------

# Script objectives:
# 	1. Subset new results data
#	2. Annotate the subset (inc study ID!)
#	3. Bind the subset to the existing combined data
#	4. Output data to /files/ewas-sum-stats/published/STUDY-ID
#	5. Add published/STUDY-ID to "studies-to-add.txt"

args <- commandArgs(trailingOnly = TRUE)
file_dir <- args[1]

files <- list.files(file_dir)

x <- read.csv(file.path(file_dir, files[1]))
print(x[1,1])

# File uploaded into temp directory
# If it passes initial tests gets moved to /files/ewas-sum-stats/published/to-add/NAME
# Report is generated
# If it passes report tests it gets moved to /files/ewas-sum-stats/published/STUDY-ID
# 	and it gets bound to data in /files/ewas-sum-stats/combined_data/

