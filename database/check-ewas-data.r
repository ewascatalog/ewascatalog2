# ------------------------------------------
# Checking format of new data to enter into the catalog
# ------------------------------------------

# 
args <- commandArgs(trailingOnly = TRUE)
file <- args[1]
file_dir <- args[2]

library(readr)

results_path <- file.path(file_dir, file, "results.txt")
studies_path <- file.path(file_dir, file, "studies.txt")

if (!file.exists(results_path)) stop("Results file not present in path provided")
if (!file.exists(studies_path)) stop("Studies file not present in path provided")

# read in data 
results <- read_tsv(results_path)
studies <- read_tsv(studies_path)

# Column names
####  Change this so it looks at mysql database columns?
####  Not sure if that would take up more time though...
studies_cols <- c("Author", 
				  "Consortium", 
				  "PMID", 
				  "Date", 
				  "Trait", 
				  "EFO", 
				  "Analysis", 
				  "Source", 
				  "Outcome", 
				  "Exposure", 
				  "Covariates", 
				  "Outcome_Units", 
				  "Exposure_Units", 
				  "Methylation_Array", 
				  "Tissue", 
				  "Further_Details", 
				  "N", 
				  "N_Cohorts", 
				  "Categories", 
				  "Age",
				  "N_Males", 
				  "N_Females", 
				  "N_EUR", 
				  "N_EAS", 
				  "N_SAS", 
				  "N_AFR", 
				  "N_AMR", 
				  "N_OTH", 
				  "StudyID")

results_cols <- c("CpG", 
				  "Location", 
				  "Chr", 
				  "Pos", 
				  "Gene", 
				  "Type", 
				  "Beta", 
				  "SE", 
				  "P", 
				  "Details", 
				  "StudyID")

if (!all(colnames(results) == results_cols)) {
	stop("Results file column names do not match the template columns")
} else if (!all(colnames(studies) == studies_cols)) {
	stop("Studies file column names do not match the template columns")
}

# Could add something to test if correct data type? 

message("Data in ", file, "looks fine")
