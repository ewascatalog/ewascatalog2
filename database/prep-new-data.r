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
# res_dir <- "../files/ewas-sum-stats/published/to-add/Thomas_Battram"
# file_dir <- "../files"

library(ewaff)

files <- list.files(res_dir)

if (!file.exists(res_dir)) {
	stop(paste("Results directory,", res_dir, ", does not exist"))
}
if (!file.exists(file_dir)) {
	stop(paste("File directory,", file_dir, ", does not exist"))
}

out_dir <- file.path(file_dir, "ewas-sum-stats/published", unique(sid))

if (!file.exists(out_dir)) {
	message("Making new directory: ", out_dir)
	system(paste("mkdir", out_dir))
}

studies <- read.csv(file.path(res_dir, files[2])) # WILL NEED TO FIGURE THIS OUT!
results <- read.csv(file.path(res_dir, files[1])) # WILL NEED TO FIGURE THIS OUT!

cpg_annotations <- data.table::fread(file.path(file_dir, "cpg_annotation.txt"))

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

report_file <- file.path(getwd(), out_dir, "upload-report.html")
print("Rendering report")
# rmarkdown::render("/code/database/upload-report-two.rmd")
# rmarkdown::render("database/upload-report-two.rmd", output_file = report_file)
# system(paste("open", report_file))

# ----------------------------------------------------
# subset and write out
# ----------------------------------------------------

full_results <- full_results[results$P < 1e-4, ]

message("Writing results to: ", out_dir)
write.table(studies, file = file.path(out_dir, "studies.txt"),
			col.names = T, row.names = F, quote = F, sep = "\t")
write.table(full_results, file = file.path(out_dir, "results.txt"),
			col.names = T, row.names = F, quote = F, sep = "\t")

# Write to studies-to-add.txt --> APPEND!!! 
studies_to_add_file <- file.path(file_dir, "ewas-sum-stats/studies-to-add.txt")
studies_to_add <- readLines(studies_to_add_file)

sid_to_add <- paste0("published/", unique(sid))
sid_to_add <- sid_to_add[!sid_to_add %in% studies_to_add]
message("Appending results directory to: ", studies_to_add_file)
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
