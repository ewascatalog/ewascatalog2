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

# res_dir <- paste0(local_rdsf_dir, "data/", cohort, "/results/")
res_dir <- file.path("results", cohort)

if (!file.exists(res_dir)) stop("File path not found!")

# cpg annotations
cpg_anno_file <- "cpg_annotation.txt"
if (!file.exists(cpg_anno_file)) stop("move cpg annotation file from rdsf")
cpg_anno <- read_tsv(cpg_anno_file)

# file paths 
raw_path <- file.path(res_dir, "raw/")
derived_path <- file.path(res_dir, "derived/")

extra_cohort_dirs <- list.files(raw_path)

dir <- extra_cohort_dirs[1]
sub_res <- map_dfr(extra_cohort_dirs, function(dir) {
	print(dir)
	raw_res_path <- file.path(raw_path, dir, "full_stats/")
	raw_res_files <- list.files(raw_res_path)
	dir_sub_res <- map_dfr(raw_res_files, function(x) {
		full_out_nam <- gsub(".txt", "_full_stats.txt", x)
		df <- read_tsv(paste0(raw_res_path, x)) %>%
			rename(CpG = probeID, Beta = estimate, SE = se, P = p.value) %>%
			left_join(cpg_anno) %>%
			dplyr::select(CpG, Location, Chr, Pos, Gene, Type, Beta, SE, P, Details, StudyID)
		
		# write it out to the rdsf
		derived_res_nam <- file.path(derived_path, dir, full_out_nam)
		write.table(df, file = derived_res_nam, 
				col.names = T, row.names = F, quote = F, sep = "\t")

		# now just take values of p<1x10-4
		sub_df <- df %>%
			dplyr::filter(P < 1e-4)
		return(sub_df)
	})
	return(dir_sub_res)
})

results_nam <- paste0(derived_path, "results.txt")
write.table(sub_res, file = results_nam, 
			col.names = T, row.names = F, quote = F, sep = "\t")
