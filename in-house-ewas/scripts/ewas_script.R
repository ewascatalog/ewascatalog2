# ----------------------------------------
# ewas script
# ----------------------------------------

pkgs <- c("tidyverse", "ewaff")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")

read_filepaths("filepaths.sh")

args <- commandArgs(trailingOnly = TRUE)
cohort <- args[1]

# make sure the cohort has a slash in it! 
if (!grepl("\\/", cohort)) cohort <- paste0(cohort, "/")

meth_file <- paste0("data/", cohort, "cleaned_FOM_data.RData")
load(meth_file)
###
### These files should be renamed and the FOM data should now be put in
### a directory called "FOM"
###
### The GEO files need to be re-organised so that each of the 
### cohorts from GEO is written out in their own directories
###
pheno_file <- paste0("data/", cohort, "cleaned_phenotype_data_FOM.txt")
pheno_dat <- read_tsv(pheno_file)

# devtools::load_all("~/repos/usefunc")

# altering the names to prevent an error in the EWAS 
# colnames(dat)[grep("^\\d|^_", colnames(dat))] <- paste0("X", colnames(dat)[grep("^\\d|^_", colnames(dat))])

## CHANGE THIS --> ONLY WORKS FOR THIS ANALYSIS!
pc_covs <- grep("pc[0-9]*", colnames(pheno_dat), 
                value = TRUE, ignore.case = TRUE)
other_covs <- grep("age", colnames(pheno_dat), 
                   value = TRUE, ignore.case = TRUE)
no_cov <- length(covs)

# for ewas catalog output
get_characteristics <- function(exposure, outcome, trait, pheno_dat, age) {
  if (is.binary(pheno_dat[[trait]])) {
    x <- pheno_dat[[trait]]
    uniq_val1 <- unique(x)[1]
    uniq_val2 <- unique(x)[2]
    cats <- paste0("Number of ", uniq_val1, " values = ", table(x)[1], 
                   ", number of ", uniq_val2, " values = ", table(x)[2])
  } else {
    cats <- NA
  }    
  if (outcome == "methylation") outcome <- "DNA methylation"
  if (exposure == "methylation") exposure <- "DNA methylation"
  out_dat <- data.frame(Author = "Battram T", 
                    Consortium = toupper(cohort), 
                    PMID = NA, 
                    Date = Sys.Date(),
                    Trait = trait, 
                    EFO = NA, 
                    Analysis = NA, 
                    Source = NA, 
                    Outcome = outcome, 
                    Exposure = exposure, 
                    Covariates = "Age, ten genetic prinicipal components, 20 surrogate variables", 
                    Outcome_Units = "Beta values", 
                    Exposure_Units = NA, 
                    Methylation_Array = "Illumina HumanMethylation450", 
                    Tissue = "Whole blood", 
                    Details = NA, 
                    N = nrow(pheno_dat), 
                    N_Cohorts = 1, 
                    Categories = cats, 
                    Age = age, 
                    N_Males = NA, 
                    N_Females = NA, 
                    N_EUR = NA, 
                    N_EAS = NA, 
                    N_SAS = NA, 
                    N_AFR = NA, 
                    N_AMR = NA, 
                    N_OTH = NA
                    )
  return(out_dat)
}

do_ewas <- function(exposure, outcome, out_path, model_family) {
  # get phenotype of interest
  phen <- c(exposure, outcome)[!c(exposure, outcome) == "methylation"]
  res_file <- paste0(out_path, phen, ".txt")
  if (file.exists(res_file)) return(NULL)
  print(phen)
  
  # if (grepl("^X\\d|^X_", phen)) {
  #     sva_phen <- gsub("^X", "", phen)    
  # } else {
  #     sva_phen <- phen
  # }
	# read in the SVs for the phenotype
	# svs <- read_delim(paste0("data/", sva_phen, ".txt"), delim = "\t")
  svs <- read_tsv(paste0("data/", cohort, "svs/", phen, ".txt"))
  sv_nam <- grep("sv[0-9]", colnames(svs), value = T)

  # Prepare phenotype data
  temp_phen <- pheno %>%
  	dplyr::select(Sample_Name, one_of(phen), one_of(covs)) %>%
  	left_join(svs) %>%
  	na.omit(.)

  # Match meth to Pheno
  temp_meth <- meth[, na.omit(match(temp_phen$Sample_Name, colnames(meth)))]
  temp_phen <- temp_phen[match(colnames(temp_meth), temp_phen$Sample_Name), ]

  if (!all(temp_phen$Sample_Name == colnames(temp_meth)) stop("phenotype and DNAm data not matched.")

  model <- as.formula(paste0(outcome, " ~ ", paste(c(exposure, covs), collapse = " + "), " + ", paste(sv_nam, collapse = " + ")))

  # Run EWAS using ewaff
  tryCatch({
      obj <- ewaff.sites(model, variable.of.interest = phen,
      methylation = temp_meth, data = temp_phen, method = "glm", 
      generate.confounders = NULL, family = model_family)

      res <- obj$table %>%
      	rownames_to_column(var = "probeID") %>%
      	dplyr::select(probeID, estimate, se, p.value)

      write.table(res, file = res_file, sep = "\t", col.names = T, row.names = F, quote = F)
      print(paste0("Results for ", phen, " saved."))
  }, error = function(e) {
      print(paste0("Error in EWAS of ", phen, ". Variance of ", phen, " = ", var(temp_phen[[phen]])))
  })

  # output the data needed for EWAS catalog
  cats <- get_categories(temp_phen[[phen]])
  out_dat <- data.frame(Author = "Battram T", 
                    Consortium = NA, 
                    PMID = NA, 
                    Date = Sys.Date(),
                    Trait = phen, 
                    EFO = NA, 
                    Analysis = NA, 
                    Source = NA, 
                    Outcome = "DNA methylation", 
                    Exposure = phen, 
                    Covariates = "Age, ten genetic prinicipal components, 20 surrogate variables", 
                    Outcome_Units = "Beta values", 
                    Exposure_Units = NA, 
                    Methylation_Array = "Illumina HumanMethylation450", 
                    Tissue = "Whole blood", 
                    Details = NA, 
                    N = nrow(temp_phen), 
                    N_Cohorts = 1, 
                    Categories = cats, 
                    Age = comma(mean(temp_phen$age)), 
                    N_Males = 0, 
                    N_Females = nrow(temp_phen), 
                    N_EUR = nrow(temp_phen), 
                    N_EAS = 0, 
                    N_SAS = 0, 
                    N_AFR = 0, 
                    N_AMR = 0, 
                    N_OTH = 0
                    )
  return(out_dat)
}

# Make a loop to run the EWAS
dat_list <- vector(mode = "list", length = length(phen_list))
for (i in seq_along(phen_list)) {
    p <- phen_list[i]
    dat_list[[i]] <- do_ewas(p, "results/")
}
# for the EWAS catalog! 
fin_dat <- do.call(rbind, dat_list)
fin_dat <- fin_dat %>%
  mutate(Trait = gsub("_*FOM1", "", Trait)) %>%
  mutate(Trait = gsub("_+g", "", Trait)) %>%
  mutate(Trait = gsub("DV_+", "", Trait)) %>%
  mutate(Trait = gsub("_+cm[0-9]?", "", Trait)) %>%
  mutate(Trait = gsub("_+mm[0-9]?", "", Trait)) %>%
  mutate(Trait = gsub("_+mmol_l", "", Trait)) %>%
  mutate(Trait = gsub("_+percent", "", Trait)) %>%
  mutate(Exposure_Units = gsub(".*__", "", Exposure)) %>%
  mutate(Exposure = Trait)

write.table(fin_dat, file = "alspac_ewas_characteristics.txt", quote = F, row.names = F, col.names = T, sep = "\t")

