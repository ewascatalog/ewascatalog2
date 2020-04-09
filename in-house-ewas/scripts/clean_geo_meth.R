# ---------------------------------------------
# checking geo methylation data and make SVs
# ---------------------------------------------

pkgs <- c("tidyverse")
lapply(pkgs, require, character.only = TRUE)

source("scripts/make_svs.R")

# ---------------------------------------------
# load in data! 
# ---------------------------------------------

geo_path <- "data/geo"
geo_accessions <- read_tsv(file.path(geo_path, "geo_accession.txt"), 
						   col_names = FALSE) %>% pull(X1)


# ---------------------------------------------
# loop over datasets
# ---------------------------------------------

# to check
# 1. column names match the sample_name column in the pheno data
# 2. data is there

# loading function that allows you to name the thing being loaded into R
new_load <- function(file) {
	temp_space <- new.env()
	var <- load(file, temp_space)
	out <- get(var, temp_space)
	rm(temp_space)
	return(out)
}

ga=geo_accessions[1]
lapply(geo_accessions, function(ga) {
	## load in data
	ga_path <- file.path(geo_path, ga)
	# methylation data
	meth_file_nam <- paste0(tolower(ga), ".rda")
	meth_file <- file.path(ga_path, meth_file_nam)
	if (!file.exists(meth_file)) stop("meth file doesn't exist")
	meth <- new_load(meth_file)	
	cols <- colnames(meth)
	# pheno data
	pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
	pheno_dat <- read_tsv(pheno_file)
	meta_file <- file.path(ga_path, "phenotype_metadata.txt")
	meta_dat <- read_tsv(meta_file)

	# make SVs
	lapply(meta_dat$phen, function(phen) {
		generate_svs(trait = phen, 
					 phen_data = pheno_dat, 
					 meth_data = meth, 
					 covariates = "", 
					 nsv = 20, 
					 out_path = paste0(ga_path, "/"), 
					 samples = "sample_name")
	})
})

# So generate SVs doesn't work when there are no covariates because
# as.formula fucks up! 

trait = meta_dat$phen 
phen_data = pheno_dat
meth_data = meth 
covariates = ""
nsv = 20
out_path = paste0(ga_path, "/")
samples = "sample_name"


