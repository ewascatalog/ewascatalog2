# ----------------------------------------
# formatting ewas results for the catalog
# ----------------------------------------

pkgs <- c("tidyverse", "readxl", "openxlsx")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
read_filepaths("filepaths.sh")

args <- commandArgs(trailingOnly = TRUE)
cohort <- args[1]
extra_cohort_info <- args[2]
# cohort <- "alspac"
# cohort <- "geo"
# extra_cohort_info <- "FOM"
# extra_cohort_info <- "GSE101961"

# ADJUSTMENT TO MAKE
# -- At end of script in data/cohort/results there will be 
#    a single results.txt and studies.txt file! as well as 
#	 the full summary stats of the extra bits (which will be in e.g. GSE1234)
# -- Script now looks through all directories of res_dir for "extra_cohort_info"
# -- The script will loop over new directories
# -- Should be a way of checking which files have been added to results.txt
# 	 and studies.txt anyway... --> If it has the full sum stats present
#	 it will have been saved to results.txt and studies.txt!!!
# -- 

res_dir <- paste0(local_rdsf_dir, "data/", cohort, "/results/")

if (!file.exists(res_dir)) stop("File path not found!")

# cpg annotations
cpg_anno_file <- "../files/cpg_annotation.txt"
cpg_anno <- read_tsv(cpg_anno_file)

# file paths 
raw_path <- paste0(res_dir, "raw/", extra_cohort_info, "/")
raw_res_path <- paste0(raw_path, "full_stats/")
derived_path <- paste0(res_dir, "derived/", extra_cohort_info, "/")

# -------------------------------------------------
# Edit characteristics files
# -------------------------------------------------
raw_files <- list.files(raw_path)
derived_files <- list.files(derived_path)
char_files <- grep("catalog_meta_data", raw_files, value = T)
edited_char_files <- grep("catalog_meta_data", derived_files, value = T)
if (length(edited_char_files) == 0) {
	lapply(char_files, function(file) {
		file_path <- paste0(raw_path, file)
		df <- read_tsv(file_path)
		new_file_nam <- gsub(".txt", ".xlsx", file)
		new_file_path <- paste0(derived_path, new_file_nam)
		write.xlsx(df, new_file_path)
	})
	stop("Edit the spreadsheets and come back!")
}

# now extract the char

# -------------------------------------------------
# Edit results files
# -------------------------------------------------
raw_res_files <- list.files(raw_res_path)

# loop over res files
sub_res <- map_dfr(raw_res_files, function(x) {
	print(x)
	full_out_nam <- gsub(".txt", "_full_stats.txt", x)
	df <- read_tsv(paste0(raw_res_path, x)) %>%
		rename(CpG = probeID, Beta = estimate, SE = se, P = p.value) %>%
		left_join(cpg_anno) %>%
		dplyr::select(CpG, Location, Chr, Pos, Gene, Type, Beta, SE, P, Details, StudyID)

	# write it out to the rdsf
	write.table(df, file = paste0(derived_path, full_out_nam), 
				col.names = T, row.names = F, quote = F, sep = "\t")

	# now just take values of p<1x10-4
	sub_df <- df %>%
		dplyr::filter(P < 1e-4)
	return(sub_df)
})

sub_char_dat <- char_dat %>%
	dplyr::filter(StudyID %in% sub_res$StudyID)

sub_out_dir <- paste0("files/ewas-sum-stats/sub/", cohort, "/") 

# write out sub res
write.table(sub_res, file = paste0(sub_out_dir, "results.txt"), 
			col.names = T, row.names = F, quote = F, sep = "\t")

# AND sub studie data
write.table(sub_char_dat, file = paste0(sub_out_dir, "studies.txt"), 
			col.names = T, row.names = F, quote = F, sep = "\t")

### will have to manually move full summary stats over! 



