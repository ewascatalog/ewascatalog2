# ------------------------------------------
# Checking format of new data to enter into the catalog
# ------------------------------------------

# 
args <- commandArgs(trailingOnly = TRUE)
sfile <- args[1]
rfile <- args[2]

# sfile <- "../../studies_test.csv"
# rfile <- "../../results_test.csv"

if (!file.exists(rfile)) stop(cat("The results file doesn't exist"))
if (!file.exists(sfile)) stop(cat("The studies file doesn't exist"))

# read in data 
results <- read.csv(rfile, stringsAsFactors = FALSE)
studies <- read.csv(sfile, stringsAsFactors = FALSE)

# ------------------------------------------
# Functions to check data
# ------------------------------------------

# function to check character length of data
# character length has been determined in "database/create-cpg-table.sql"
check_nchar <- function(dat_nam, max_nchars) {
	lapply(max_nchars, function(n) {
		var <- get(paste0("char", n))
		dat <- get(dat_nam)
		lapply(var, function(x) {
			all_vals <- dat[[x]]
			if (all(is.na(all_vals))) return(NULL)
			if (any(nchar(all_vals) > n)) {
				cat(paste("A value in the", x, "column in the", dat_nam, "data is too long", 
						  "please make sure it is", n, "characters or fewer."))
				quit("no")
			}
		})
	})
}

# function to check columns for NAs
check_required_cols <- function(dat_nam, cols) {
	dat <- get(dat_nam)
	lapply(cols, function(col) {
		vals <- dat[[col]]
		if (any(is.na(vals))) {
			cat(paste("A value in the", col, "column in the", dat_nam, "data is missing", 
					  "and this is a required column."))
			quit("no")
		} else {
			return(NULL)
		}
	})
}

# ------------------------------------------
# Studies data checks
# ------------------------------------------

### Column names are present
# NOTE: Change this so it looks at mysql database columns?
#  		Not sure if that would take up more time though...
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
				  "N_OTH")

optional_studies_cols <- c("StudyID")

# studies <- as.data.frame(matrix(nrow = 1, ncol = length(studies_cols)))
# colnames(studies) <- studies_cols
# write.csv(studies, "studies_test.csv", 
# 		  row.names = F, quote = F)

if (!all(colnames(studies) == studies_cols)) {
	cat("Studies file column names do not match the template columns")
	quit("no")
}

### Required columns are filled in
required_cols <- c("Author", "Trait", "Outcome", "Exposure", "Methylation_Array", "Tissue")
tmp <- check_required_cols("studies", required_cols)

### Character length doesn't exceed that set in mysql database 
char50 <- c("Author", "Consortium", "Source", "Outcome_Units", "Exposure_Units",
			"Array")
char20 <- c("PMID", "Date", "N", "N_Cohorts", "Age", "N_Males", "N_Females",
			"N_EUR", "N_EAS", "N_SAS", "N_AFR", "N_OTH")
char100 <- "Tissue"
char300 <- "Covariates"
char200 <- studies_cols[!studies_cols %in% c(char50, char20, char100, char300)]

max_chars <- c(20, 50, 100, 200, 300)
tmp <- check_nchar("studies", max_chars)

# ------------------------------------------
# Results data checks
# ------------------------------------------

### Column names are present
results_cols <- c("CpG", 
				  "Beta", 
				  "SE", 
				  "P", 
				  "Details")

# results <- as.data.frame(matrix(nrow = 1, ncol = length(results_cols)))
# colnames(results) <- results_cols
# write.csv(results, "results_test.csv", 
#  		  row.names = F, quote = F)

if (!all(colnames(results) == results_cols)) {
	cat("Results file column names do not match the template columns")
	quit("no")
}

### Required columns are filled in
required_cols <- c("CpG", "P")
tmp <- check_required_cols("results", required_cols)

### Character length doesn't exceed that set in mysql database 
char20 <- c("CpG", "Beta", "SE")
char50 <- c("P")
char200 <- c("Details")
max_chars <- c(20, 50, 200)
tmp <- check_nchar("results", max_chars)

### Check required columns are filled in correctly
if (!all(grepl("^c", results$CpG))) {
	cat("Some things that aren't CpGs are present in the CpG column of the results file")
	quit("no")
}
if (any(results$P > 1) | any(results$P < 0)) {
	cat("Not all P values provided are between 0 and 1")
	quit("no")
}


optional_results_cols <- c("Location", 
						   "Chr", 
						   "Pos", 
						   "Gene", 
						   "Type", 
						   "StudyID")	


err_msg <- function(e, r_msg = TRUE, user_msg = NULL, to_return = NA) {
  # if (r_msg) print(e)
  # if (!is.null(user_msg)) print(user_msg)
  # return(to_return)
  cat(as.character(e))
  quit("no")
}

# if (file.exists("/code/database/upload-report-one.rmd")) {
# 	library(rmarkdown)
# 	tryCatch(rmarkdown::render("/code/database/upload-report-one.rmd"),
# 		error = function(e) {err_msg(e)})
# 	# rmarkdown::render("/code/database/upload-report-one.rmd")
# }

# invisible(rmarkdown::render("/code/database/upload-report-one.rmd"))

cat("Good")
