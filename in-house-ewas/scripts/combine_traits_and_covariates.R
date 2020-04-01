# ---------------------------------------------
# Tidying traits and combining with covariates for alspac
# ---------------------------------------------

pkgs <- c("tidyverse")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
source("scripts/make_svs.R")

read_filepaths("filepaths.sh")
# 
setwd(bc_home_dir)

# ---------------------------------------------
# load in data! 
# ---------------------------------------------

# aries ids file
aries_ids <- read_tsv(paste0("data/alspac/", aries_ids_file))
# pcs
pcs <- read.table(paste0("data/alspac/", timepoints, "_pcs.eigenvec"), sep = " ", header = F, stringsAsFactors = F) 
head(pcs)
colnames(pcs) <- c("FID", "IID", paste0(rep("PC", times = 20), 1:20))
pcs$ALN <- gsub("[A-Z]", "", pcs[["FID"]])
pcs <- dplyr::select(pcs, -IID, -FID)
pc_cols <- colnames(pcs)[colnames(pcs) != "ALN"]

# samplesheet
load(samplesheet_file)
head(samplesheet)

# phenotype file
phen_dat <- read_tsv(paste0("data/alspac/phenotype_data_", timepoints, ".txt"))
phen_cols <- colnames(phen_dat)

# meta-data file
phen_meta <- read_tsv(paste0("data/alspac/phenotype_metadata_", timepoints, ".txt"))

# ---------------------------------------------
# combine data! 
# ---------------------------------------------

all_dat <- samplesheet %>%
	dplyr::filter(ALN %in% aries_ids$ALN & time_point == timepoints) %>%
	left_join(pcs) %>%
	mutate(aln = as.numeric(ALN)) %>%
	left_join(phen_dat) %>%
	dplyr::select(one_of(phen_cols), age, one_of(pc_cols))

# ---------------------------------------------
# check phenotype data 
# ---------------------------------------------


# ---------------------------------------------
# make SVs here or separate script??
# ---------------------------------------------

# impute data

# make svs
sv_res <- generate_svs()

# ---------------------------------------------
# save it all
# ---------------------------------------------

# bind sv_res and rest of data

