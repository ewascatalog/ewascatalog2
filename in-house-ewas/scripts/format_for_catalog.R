# ----------------------------------------
# formatting ewas results for the catalog
# ----------------------------------------

pkgs <- c("tidyverse", "readxl")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
read_filepaths("filepaths.sh")

cohort <- "" # FILL THIS IN 
# cohort <- "alspac"
# cohort <- "geo"

res_dir <- paste0(local_rdsf_dir, "data/", cohort, "/results/")

if (!file.exists(res_dir)) stop("File path not found!")

# cpg annotations
cpg_anno_file <- "files/cpg_annotation.txt"
cpg_anno <- read_tsv(cpg_anno_file)

# get files
raw_path <- paste0(res_dir, "raw/")
files <- list.files(raw_path)
char_files <- grep("catalog_meta_data", files, value = T)
edited_char_files <- grep("xlsx", files, value = T)
res_files <- files[!files %in% char_files]

# -------------------------------------------------
# Read in characteristics file and put study ID in
# -------------------------------------------------

# PROBLEM!!! --> Could get duplicates of study ID

derived_path <- paste0(res_dir, "derived/")

# loop over res files
sub_res <- map_dfr(res_files, function(x) {
	print(x)
	full_out_nam <- gsub(".txt", "_full_stats.txt", x)
	df <- read_tsv(paste0(raw_path, x)) %>%
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



