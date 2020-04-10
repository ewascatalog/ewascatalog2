# ---------------------------------------------
# checking geo methylation data and make SVs
# ---------------------------------------------

pkgs <- c("tidyverse", "sva", "SmartSVA", "matrixStats")
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

make_dir <- function(path) {
    system(paste("mkdir", path))
}

check_cols <- function(meth_dat, phen_dat) {
	cols <- colnames(meth_dat)
	out <- ifelse(all(cols %in% phen_dat$sample_name), "good", "bad")
	return(out)
}

# very primitive, but should be fine for now!
check_rows <- function(meth_dat) {
	rows <- rownames(meth_dat)
	out <- ifelse(any(grepl("cg[0-9]*", rows)), "good", "bad")
	return(out)
}

check_betas <- function(meth_dat, n) {
	b1_10 <- meth_dat[sample(1:nrow(meth_dat), n), ]
	test <- map_lgl(1:nrow(b1_10), function(x) {
		cpg <- b1_10[x, ]
		cpg <- cpg[!is.na(cpg)]
		out <- any(cpg > 1 | cpg < 0)
		return(out)
	})
	out <- ifelse(any(test), "bad", "good")
	return(out)
}


ga=geo_accessions[1] # SHOULD WORK!
# check colnames and rownames
lapply(geo_accessions, function(ga) {
	## load in data
	print(ga)
	ga_path <- file.path(geo_path, ga)
	# methylation data
	meth_file_nam <- paste0(tolower(ga), ".rda")
	meth_file <- file.path(ga_path, meth_file_nam)
	if (!file.exists(meth_file)) stop("meth file doesn't exist")
	meth <- new_load(meth_file)	
	# pheno data
	pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
	pheno_dat <- read_tsv(pheno_file)
	meta_file <- file.path(ga_path, "phenotype_metadata.txt")
	meta_dat <- read_tsv(meta_file)

	# check colnames are samples
	col_test <- check_cols(meth, pheno_dat)
	message("columns are ",  col_test)
	# check rownames are CpG sites
	row_test <- check_rows(meth)
	message("rows are ", row_test)
	if (row_test == "bad" | col_test == "bad") {
		stop("sort out columns and rows and re-run!")
	}
	# check methylation betas 
	betas_test <- check_betas(meth, n = 10)
	message("betas are ", betas_test)
	if (betas_test == "bad") {
		stop("sort out betas")
	} else {
		message("All goood! Going ahead with generating SVs now!")
	}

	mdata <- impute_matrix(meth)
	
	sv_out_dir <- paste0(ga_path, "/svs/")
	if (!file.exists(sv_out_dir)) make_dir(sv_out_dir)
	# make SVs
	lapply(meta_dat$phen, function(phen) {
		pheno_dat[[phen]] <- type.convert(pheno_dat[[phen]])
		generate_svs(trait = phen, 
					 phen_data = pheno_dat, 
					 meth_data = mdata, 
					 covariates = "", 
					 nsv = 20, 
					 out_path = sv_out_dir, 
					 samples = "sample_name")
	})
})

# check which ones failed
lapply(geo_accessions, function(ga) {
	sv_out_dir <- paste0(file.path(geo_path, ga), "/svs/")
	if (file.exists(paste0(sv_out_dir, "sv_fails.txt"))) {
		message("making SVs failed in the ", ga, "dataset")
	}
}

# ---------------------------------------------------
# cleaning the epic array datasets! 
# ---------------------------------------------------

phenofile <- "data/geo/ewas-cat-cr02.rdata"
load(phenofile)

epic_array <- c("GSE112596", "GSE107080", "GSE118144")
# ---------------------------------------------------
# cleaning first epic array dataset
# ---------------------------------------------------
ga <- epic_array[1]
all_info <- geo[[ga]]
str(all_info)
ga_path <- file.path(geo_path, ga)
# pheno data
pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
pheno_dat <- read_tsv(pheno_file)
# methylation data
meth_file_nam <- paste0(tolower(ga), ".rda")
meth_file <- file.path(ga_path, meth_file_nam)
old_meth <- new_load(meth_file)
meth <- old_meth

colnames(meth)

# colnames look very similar to all_info$title...
cols <- gsub("-", ".", all_info$title)
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$ID
meth <- meth[, colnames(meth) != "ID"] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data
meth <- meth[, colnames(meth) %in% pheno_dat[["sample_name"]]]

# save the old version of the meth data
old_dir <- file.path(ga_path, "old_meth_data/")
if (!file.exists(old_dir)) make_dir(old_dir)
save(old_meth, file = paste0(old_dir, meth_file_nam))
# save the new data, ready for an EWAS! 
save(meth, file = meth_file)

# ---------------------------------------------------
# cleaning second epic array dataset
# ---------------------------------------------------
ga <- epic_array[2]
all_info <- geo[[ga]]
str(all_info)
ga_path <- file.path(geo_path, ga)
# pheno data
pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
pheno_dat <- read_tsv(pheno_file)
# methylation data
meth_file_nam <- paste0(tolower(ga), ".rda")
meth_file <- file.path(ga_path, meth_file_nam)
old_meth <- new_load(meth_file)
meth <- old_meth

# colnames look similar to all_info$description.2
cols <- gsub(" ", ".", all_info$description.2)
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$ID_REF
meth <- meth[, colnames(meth) != "ID_REF"] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data (from previous cleaning, see above!)
meth <- meth[, colnames(meth) %in% pheno_dat[["sample_name"]]]

# save the old version of the meth data
old_dir <- file.path(ga_path, "old_meth_data/")
if (!file.exists(old_dir)) make_dir(old_dir)
save(old_meth, file = paste0(old_dir, meth_file_nam))
# save the new data, ready for an EWAS! 
save(meth, file = meth_file)


# ---------------------------------------------------
# cleaning third epic array dataset
# ---------------------------------------------------
ga <- epic_array[3]
all_info <- geo[[ga]]
str(all_info)
ga_path <- file.path(geo_path, ga)
# pheno data
pheno_file <- file.path(ga_path, "cleaned_phenotype_data.txt")
pheno_dat <- read_tsv(pheno_file)
# methylation data
meth_file_nam <- paste0(tolower(ga), ".rda")
meth_file <- file.path(ga_path, meth_file_nam)
old_meth <- new_load(meth_file)
meth <- old_meth

# colnames look similar to all_info$title
cols <- paste(gsub(":.*", "", all_info$title), "AVG_Beta", sep = ".")
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$TargetID
meth <- meth[, colnames(meth) != "TargetID"] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data (from previous cleaning, see above!)
meth <- meth[, colnames(meth) %in% pheno_dat[["sample_name"]]]

# save the old version of the meth data
old_dir <- file.path(ga_path, "old_meth_data/")
if (!file.exists(old_dir)) make_dir(old_dir)
save(old_meth, file = paste0(old_dir, meth_file_nam))
# save the new data, ready for an EWAS! 
save(meth, file = meth_file)

