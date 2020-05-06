# ------------------------------------------
# Checking format of new data to enter into the catalog
# ------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
file <- args[1]

# library(readr)

x <- read.csv(file)
cols <- colnames(x)

if ("Author" %in% cols) {
	cat("Good")
} else {
	cat("Bad")
}