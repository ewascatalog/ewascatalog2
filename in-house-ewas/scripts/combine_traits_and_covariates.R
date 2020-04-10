# ---------------------------------------------
# Tidying traits and combining with covariates for alspac
# ---------------------------------------------

pkgs <- c("tidyverse", "sva", "SmartSVA", "matrixStats")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")
source("scripts/gen_svs_functions.R")

read_filepaths("filepaths.sh")

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
pcs_to_keep <- paste0(rep("PC", times = 10), 1:10)
pc_cols <- pcs_to_keep

# samplesheet
load(samplesheet_file)
head(samplesheet)

# phenotype file
phen_dat <- read_tsv(paste0("data/alspac/phenotype_data_", timepoints, ".txt"))
phen_cols <- colnames(phen_dat)

# meta-data file
phen_meta <- read_tsv(paste0("data/alspac/phenotype_metadata_", timepoints, ".txt"))

# methylation file
meth_file <- paste0("data/alspac/cleaned_", timepoints, "_data.RData")
if (!file.exists(meth_file)) stop("CLEAN YOUR METHYLATION DATA AND PUT IT IN THE RIGHT PLACE!")
load(meth_file)

# ---------------------------------------------
# check phenotype data 
# ---------------------------------------------

traits <- phen_meta$phen
alnqlet_cols <- grep("aln|qlet", phen_cols, value = T, ignore.case = T)

# set outliers to missing
set_outliers_to_na <- function(x) {
	q <- quantile(x, probs = c(0.25, 0.75), na.rm = T)
	iqr <- q[2] - q[1]
	too_hi <- which(x > q[2] + 3 * iqr)
	too_lo <- which(x < q[1] - 3 * iqr)
	if (length(c(too_lo,too_hi)) > 0) x[c(too_lo, too_hi)] <- NA
	return(x)
}

no_out_phen <- map_dfc(phen_cols, function(trait) {
	var <- phen_dat[[trait]]
	if (trait %in% alnqlet_cols) return(var)
	out <- set_outliers_to_na(var)
	return(out)
})
colnames(no_out_phen) <- phen_cols

# check zero values
count_zero <- map_dbl(phen_cols, function(x) sum(no_out_phen[[x]] == 0, na.rm = T))
names(count_zero) <- phen_cols
zero_vals <- names(count_zero[count_zero > 0])
# all metabolites and clin measures --> Setting to NA
no_zero_phen <- map_dfc(phen_cols, function(trait) {
	var <- no_out_phen[[trait]]
	if (!trait %in% zero_vals) return(var)
	out <- ifelse(var == 0, NA, var)
	return(out)
})
colnames(no_zero_phen) <- phen_cols

# check negative values
count_neg <- map_dbl(phen_cols, function(x) sum(no_zero_phen[[x]] < 0, na.rm = T))
names(count_neg) <- phen_cols
neg_vals <- names(count_neg[count_neg > 0])
# some traits have negative values that shouldn't (all -1 so probs a label)
odd_neg_var <- c("Hip_cortical_width_neck__FOM1", 
				 "Hip_cortical_ratio_neck__FOM1", 
				 "Hip_cortical_width_calcar__FOM1", 
				 "Hip_cortical_ratio_calcar__FOM1")
# set negative values in traits to NA
no_neg_phen <- map_dfc(phen_cols, function(trait) {
	var <- no_zero_phen[[trait]]
	if (!trait %in% odd_neg_var) return(var)
	out <- ifelse(sign(var) == -1, NA, var)
	return(out)
})
colnames(no_neg_phen) <- phen_cols

# check for normality
norm_test_res <- map_dfr(traits, function(trait) {
	var <- no_neg_phen[[trait]]
	sw <- shapiro.test(var)
	out <- tibble(phen = trait, sw_pval = sw$p)
	return(out)
})
norm_test_res
write.table(norm_test_res, file = paste0("data/alspac/phenotype_normality_tests_", timepoints, ".txt"),
			col.names = T, row.names = F, quote = F, sep = "\t")
# most seem to be non-normal, but DNAm is outcome so just check
# residuals after ewas and redo those that need it! 

fin_phen <- no_neg_phen

# ---------------------------------------------
# combine data! 
# ---------------------------------------------

all_dat <- samplesheet %>%
	dplyr::filter(ALN %in% aries_ids$ALN & time_point == timepoints) %>%
	left_join(pcs) %>%
	mutate(aln = as.numeric(ALN)) %>%
	left_join(fin_phen) %>%
	dplyr::select(Sample_Name, one_of(phen_cols), age, one_of(pc_cols))

# ---------------------------------------------
# make SVs
# ---------------------------------------------
mdata <- as.matrix(meth)
cov <- c("age", pc_cols)

# impute data
mdata <- impute_matrix(mdata)

# make svs
### loop over all traits and save out results -- need diff results for each trait! 
out_dir <- "data/alspac/svs/"
if (!file.exists(out_dir)) stop("MAKE DIRECTORY!")
lapply(traits, function(trait) {
	start_time <- proc.time()
	generate_svs(
		trait = trait, 
		phen_data = all_dat, 
		meth_data = mdata, 
		covariates = cov, 
		nsv = 20, 
		out_path = out_dir
		)
	time_taken <- proc.time() - start_time
	print(time_taken)
	return(NULL)
})

# ---------------------------------------------
# save it all
# ---------------------------------------------
# SVs already written out so just writing out other data

nam <- paste0("data/alspac/cleaned_phenotype_data_", timepoints, ".txt")
write.table(all_dat, file = nam, 
			col.names = T, row.names = F, quote = F, sep = "\t")








