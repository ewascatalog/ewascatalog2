# ----------------------------------------------------
# Sort new ewas data for input into catalog
# ----------------------------------------------------

# Script objectives:
#	1  Annotate the data (inc study ID!)
#	2. Generate report
# 	3. Subset results
#	4. Output data to FILE_DIR/ewas-sum-stats/published/STUDY-ID
#	5. Add published/STUDY-ID to "studies-to-add.txt"

options(stringsAsFactors = FALSE)

args <- commandArgs(trailingOnly = TRUE)
res_dir <- args[1]
file_dir <- args[2]
# res_dir <- "../files/ewas-sum-stats/published/to-add/Tom_Battram"
# file_dir <- "../files"

files <- list.files(res_dir)

studies <- read.csv(file.path(res_dir, files[2])) # WILL NEED TO FIGURE THIS OUT!
results <- read.csv(file.path(res_dir, files[1])) # WILL NEED TO FIGURE THIS OUT!

cpg_annotations <- data.table::fread(file.path(file_dir, "cpg_annotation.txt"))

# for tests:
# results <- data.frame(CpG = sample(cpg_annotations$CpG, 10000), 
# 						Beta = NA, 
# 						SE = NA, 
# 						P = runif(10000), 
# 						Details = NA)

# ----------------------------------------------------
# annotate
# ---------------------------------------------------- 

full_results <- dplyr::left_join(results, cpg_annotations)

generate_study_id <- function(studies_dat) {
  df <- studies_dat
  auth_nam <- gsub(" ", "-", df$Author)
  trait_nam <- gsub(" ", "_", tolower(df$Trait))
  if (is.na(df$PMID)) {
    pmid <- NULL
  } else {
    pmid <- df$PMID
  }
  StudyID <- paste(c(pmid, auth_nam, trait_nam), collapse = "_")
  return(StudyID)
}

sid <- generate_study_id(studies)
studies$Study_ID <- sid
full_results$Study_ID <- sid

out_dir <- file.path(file_dir, "ewas-sum-stats/published", unique(sid))

# ----------------------------------------------------
# generate report
# ----------------------------------------------------
# for report:
# 	1. SE distribution 
#	2. Beta distribution + outliers
#	3. qq and manhattan 
#	4. Number of sites that passed P<1e-7 + P<1e-4
#	5. If EFO term is present 
#	6. List of things to do
# library(ewaff)

# no betas (will also equal no SEs) -> Nothing
# no SEs (not gonna bother!) -> No standard error plot
# some missing data 

betas_present <- any(!is.na(full_results$Beta))
se_present <- any(!is.na(full_results$SE))

# beta outliers
tukey_test <- function(vals) {
	iqr <- IQR(vals)
	q1 <- quantile(vals)["25%"]
	q3 <- quantile(vals)["75%"]
	lower_bound <- q1 - 3 * iqr
	upper_bound <- q3 + 3 * iqr
	vals_outside_bounds <- !between(vals, lower_bound, upper_bound)
	return(vals_outside_bounds)
}

# distributions of beta + se
if (betas_present) {
	beta_hist <- hist(full_results$Beta)
	beta_range <- range(full_results$Beta)
	beta_out <- tukey_test(results$Beta)
}
if (se_present) {
	se_hist <- hist(full_results$SE)
	se_range <- range(full_results$SE)	
}

# qq + manhattan
# qq.plot <- ewaff.qq.plot(full_results$P)

# manhattan.plot <- ewaff.manhattan.plot(chr = full_results$Chr,
#                                        pos = full_results$Pos, 
#                                        estimates = full_results$Beta, 
#                                        p.values = full_results$P)

# N associations
n_p7 <- sum(full_results$P < 1e-7)
n_p4 <- sum(full_results$P < 1e-4)

# rmarkdown::render("/code/database/upload-report-two.rmd")
# rmarkdown::render("upload-report-two.rmd")

# ----------------------------------------------------
# subset and write out
# ----------------------------------------------------

full_results <- full_results[results$P < 1e-4, ]

if (!file.exists(out_dir)) {
	system(paste("mkdir", out_dir))
}

write.table(studies, file = file.path(out_dir, "studies.txt"),
			col.names = T, row.names = F, quote = F, sep = "\t")
write.table(results, file = file.path(out_dir, "results.txt"),
			col.names = T, row.names = F, quote = F, sep = "\t")

# Write to studies-to-add.txt --> APPEND!!! 
studies_to_add_file <- file.path(file_dir, "ewas-sum-stats/studies-to-add.txt")
studies_to_add <- read.table(studies_to_add_file, header = F, sep = "\n")
studies_to_add <- studies_to_add[[1]]

sid_to_add <- unique(sid)[!unique(sid) %in% studies_to_add]
write.table(sid_to_add, file = file.path(file_dir, "ewas-sum-stats/studies-to-add.txt"),
			col.names = F, row.names = F, quote = F, sep = "\n", append = T)

# ----------------------------------------------------
# bind to old results ---> THIS SHOULD NOW BE PART OF STEP 2!
# ----------------------------------------------------

all_dat_dir <- file.path(file_dir, "ewas-sum-stats/combined_data")

# write.table(studies, file = file.path(all_dat_dir, "studies.txt"),
# 			col.names = F, row.names = F, quote = F, sep = "\t", append = T)
# write.table(results, file = file.path(all_dat_dir, "results.txt"),
# 			col.names = F, row.names = F, quote = F, sep = "\t", append = T)
