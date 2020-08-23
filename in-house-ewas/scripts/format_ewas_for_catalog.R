# --------------------------------------------------------
# Script for formatting EWAS results for the catalog
# --------------------------------------------------------

# Just format results so they're ready for pipeline:
# 1. Bind all the meta files together for the studies file
# 2. Loop through the studies and extract data at P<1e-4
# 3. Tidy up studies file and output results into a "results/" directory

pkgs <- c("tidyverse", "readxl", "openxlsx")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
source("scripts/useful_functions.R")
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

# file paths 
raw_path <- file.path(res_dir, "raw")
derived_path <- file.path(res_dir, "derived")

extra_cohort_dirs <- list.files(raw_path)

# bind studies files together
di=extra_cohort_dirs[1]
meta_dat <- map_dfr(extra_cohort_dirs, function(di) {
	meta_files <- grep("catalog_meta_data", list.files(file.path(raw_path, di)), value=T)
	if (length(meta_files) == 0) return(NULL)
	meta_out <- map_dfr(meta_files, function(f) {
		out <- read_tsv(file.path(raw_path, di, f))
		system(paste0("rm ", raw_path, "/", di, "/", f))
		return(out)
	})
	return(meta_out)
})

# check which ewas have not run
old_meta_dat <- map_dfr(extra_cohort_dirs, function(di) {
	cohort_data_path <- file.path(cohort, di)
	pheno_meta_file <- file.path("data", cohort_data_path, "phenotype_metadata.txt")
	pheno_meta <- read_tsv(pheno_meta_file)
	return(pheno_meta)
})

failed_phens <- old_meta_dat %>%
	dplyr::filter(!phen %in% meta_dat$phen) %>%
	pull(phen)

studies_columns <- c("Author", "Consortium", "PMID", "Date", "Trait", 
					 "EFO", "Trait_units", "dnam_in_model", "dnam_units", 
					 "Analysis", "Source", "Covariates", "Methylation_Array", 
					 "Tissue", "Further_Details", "N", "N_Cohorts", "Age", "Sex",
					 "Ethnicity", "Results_file")
x=1
studies <- map_dfr(1:nrow(meta_dat), function(x) {
	print(x)
	df <- meta_dat[x, ]
	# read in full stats and get P<1e-4
	derived_dat <- read_tsv(df$full_stats_file) %>%
		dplyr::filter(p.value < 1e-4) %>%
		rename(CpG = probeID, Beta = estimate, SE = se, P = p.value)
	# if no results return null
	if (nrow(derived_dat) == 0) return(NULL)
	# write out results to already determined results file
	write.csv(derived_dat, file = file.path(derived_path, "results", df$Results_file), 
			  row.names = F, quote = F)
	# extract data for studies file
	studies_out <- df %>%
		dplyr::select(one_of(studies_columns))
	return(studies_out)
})

write.xlsx(studies, file = file.path(derived_path, "studies.xlsx"))
