# ----------------------------------------------------
# Sort new ewas data for input into catalog
# ----------------------------------------------------

# Script objectives:
#	1  Annotate the data (inc study ID!)
#	2. Generate report
#   3. Subset results
#	4. Output data to FILE_DIR/ewas-sum-stats/study-data/STUDY-ID
#	5. Add STUDY-ID to "studies-to-add.txt"

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
file_dir <- args[1]
inhouse_dir <- file.path(file_dir, "ewas-sum-stats/inhouse-data")
res_dir <- file.path(inhouse_dir, "results")
sfile <- "studies.xlsx"
# sfile <- "studies_template_inhouse_test.xlsx"

if (!file.exists(file.path(inhouse_dir, sfile))) {
    stop("studies.xlsx doesn't exist")
}

studies <- readxl::read_excel(file.path(inhouse_dir, sfile), sheet="data")

# ------------------------------------------
# Functions to check data
# ------------------------------------------

# function to check character length of data
# character length has been determined in "database/create-cpg-table.sql"
check_nchar <- function(dat_nam, max_nchars) 
{
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
check_required_cols <- function(dat_nam, cols) 
{
    ### Checks columns for NAs and quits if there are NAs

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

# sort study columns
sort_study_cols <- function()

#

#

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
                  # "Categories", 
                  "Age",
                  "Sex",
                  # "N_Males", 
                  # "N_Females", 
                  "Ethnicity"
                  # "N_EUR", 
                  # "N_EAS", 
                  # "N_SAS", 
                  # "N_AFR", 
                  # "N_AMR", 
                  # "N_OTH"
                  )

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


cpg_annotations <- data.table::fread(file.path(file_dir, "cpg_annotation.txt"))

# ----------------------------------------------------
# annotate
# ---------------------------------------------------- 

# full_results <- dplyr::left_join(results, cpg_annotations)

generate_study_id <- function(studies_dat) {
    df <- studies_dat
    auth_nam <- gsub(" ", "-", df$Author)
    trait_nam <- gsub(" ", "_", tolower(df$Trait))
    if (is.na(df$PMID)) {
        pmid <- NULL
    } else {
        pmid <- df$PMID
    }
    if (!is.na(df$Analysis)) {
        analysis <- gsub(" ", "_", tolower(df$Analysis))
    } else {
        analysis <- NULL
    }
        StudyID <- paste(c(pmid, auth_nam, trait_nam, analysis), collapse = "_")
    return(StudyID)
}

sid <- generate_study_id(studies)
studies$Study_ID <- sid
# full_results$Study_ID <- sid

res_cols <- c("CpG", "Location", "Chr", "Pos", "Gene", "Type", "Beta", "SE", "P", "Details", "Study_ID")

# full_results <- full_results[, res_cols]

out_dir <- file.path(file_dir, "ewas-sum-stats/study-data", unique(sid))

if (!file.exists(out_dir)) {
	message("Making new directory: ", out_dir)
	system(paste("mkdir", out_dir))
}

# ----------------------------------------------------
# generate report
# ----------------------------------------------------

betas_present <- any(!is.na(full_results$Beta))
se_present <- any(!is.na(full_results$SE))

# beta outliers
tukey_test <- function(vals) {
	iqr <- IQR(vals)
	q1 <- quantile(vals)["25%"]
	q3 <- quantile(vals)["75%"]
	lower_bound <- q1 - 3 * iqr
	upper_bound <- q3 + 3 * iqr
	vals_outside_bounds <- !dplyr::between(vals, lower_bound, upper_bound)
	return(vals_outside_bounds)
}

# distributions of beta + se
if (betas_present) {
	beta_range <- range(full_results$Beta)
	beta_out <- full_results$Beta[tukey_test(full_results$Beta)]
}
if (se_present) {
	se_range <- range(full_results$SE)	
}

# qq + manhattan
qq.plot <- ewaff.qq.plot(full_results$P)

manhattan.plot <- ewaff.manhattan.plot(chr = full_results$Chr,
                                       pos = full_results$Pos, 
                                       estimates = full_results$Beta, 
                                       p.values = full_results$P)

# N associations
n_p7 <- sum(full_results$P < 1e-7)
n_p4 <- sum(full_results$P < 1e-4)

# Top hits 
top_hits <- full_results[order(full_results$P), ]
top_hits <- top_hits[1:10, ]
top_hits <- top_hits[, c("CpG", "Beta", "SE", "P", "Location", "Gene")]
rownames(top_hits) <- NULL

report <- "upload-report-two.rmd"
report_out_file <- file.path(out_dir, "upload-report.html")
print("Rendering report")
rmdreport::rmdreport.generate(report, report_out_file)

# ----------------------------------------------------
# subset and write out
# ----------------------------------------------------

full_results <- full_results[results$P < 1e-4, ]

message("Writing results to: ", out_dir)
write.table(studies, file = file.path(out_dir, "studies.txt"),
			col.names = T, row.names = F, quote = F, sep = "\t")
write.table(full_results, file = file.path(out_dir, "results.txt"),
			col.names = T, row.names = F, quote = F, sep = "\t")

if (file.exists(file.path(res_dir, zfile))) {
    system(paste0("mv ", file.path(res_dir, rfile), " ", res_dir, "/results.csv"))
}

# Write to studies-to-add.txt --> APPEND!!! 
studies_to_add_file <- file.path(file_dir, "ewas-sum-stats/studies-to-add.txt")
studies_to_add <- readLines(studies_to_add_file)

sid_to_add <- unique(sid)
sid_to_add <- sid_to_add[!sid_to_add %in% studies_to_add]
message("Appending results directory to: ", studies_to_add_file)
write.table(sid_to_add, file = file.path(file_dir, "ewas-sum-stats/studies-to-add.txt"),
			col.names = F, row.names = F, quote = F, sep = "\n", append = T)

# FIN