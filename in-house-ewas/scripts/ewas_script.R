# ----------------------------------------
# ewas script
# ----------------------------------------

pkgs <- c("tidyverse", "ewaff")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")

read_filepaths("filepaths.sh")

args <- commandArgs(trailingOnly = TRUE)
cohort <- args[1]

cohort_path <- paste0(cohort, "/")

meth_file <- paste0("data/", cohort_path, "cleaned_FOM_data.RData")
load(meth_file)
###
### These files should be renamed and the FOM data should now be put in
### a directory called "FOM"
###
### The GEO files need to be re-organised so that each of the 
### cohorts from GEO is written out in their own directories
###
pheno_file <- paste0("data/", cohort_path, "cleaned_phenotype_data_FOM.txt")
pheno_dat <- read_tsv(pheno_file)

pheno_meta_file <- paste0("data/", cohort_path, "phenotype_metadata_FOM.txt")
pheno_meta <- read_tsv(pheno_meta_file)
traits <- pheno_meta$phen
devtools::load_all("~/repos/usefunc")

# altering the names to prevent an error in the EWAS 
# colnames(dat)[grep("^\\d|^_", colnames(dat))] <- paste0("X", colnames(dat)[grep("^\\d|^_", colnames(dat))])

## CHANGE THIS --> ONLY WORKS FOR THIS ANALYSIS!
pc_covs <- grep("pc[0-9]*", colnames(pheno_dat), 
                value = TRUE, ignore.case = TRUE)
pc_nam <- paste(length(pc_covs), "genetic principal components")
other_covs <- grep("^age$", colnames(pheno_dat), 
                   value = TRUE, ignore.case = TRUE)
other_nam <- stringr::str_to_title(other_covs)
covs <- c(pc_covs, other_covs)
cov_nam <- paste(other_nam, pc_nam, sep = ", ")
n_cov <- length(covs)

# for ewas catalog output
get_characteristics <- function(exposure, outcome, trait, pheno_dat, age, 
                                covs) {
  if (is.binary(pheno_dat[[trait]])) {
    x <- pheno_dat[[trait]]
    uniq_val1 <- unique(x)[1]
    uniq_val2 <- unique(x)[2]
    cats <- paste0("Number of ", uniq_val1, " values = ", table(x)[1], 
                   ", number of ", uniq_val2, " values = ", table(x)[2])
  } else {
    cats <- NA
  }    
  if (outcome == "methylation") {
    outcome <- "DNA methylation"
    outcome_u <- "Beta values"
    exposure_u <- NA
  } else if (exposure == "methylation") {
    exposure <- "DNA methylation"
    exposure_u <- "Beta values"
    outcome_u <- NA
  } 
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
                    Covariates = covs, 
                    Outcome_Units = outcome_u, 
                    Exposure_Units = exposure_u, 
                    Methylation_Array = "Illumina HumanMethylation450", 
                    Tissue = "Whole blood", 
                    Further_Details = NA, 
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

generate_study_id <- function(char_dat) {
  df <- char_dat
  auth_nam <- gsub(" ", "-", df$Author)
  trait_nam <- gsub(" ", "_", tolower(df$Trait))
  StudyID <- paste(auth_nam, trait_nam, N, sep = "_")
  return(StudyID)
}

run_ewas <- function(exposure, outcome, out_path, model_family, meth_dat,
                    pheno_dat) {
  # get phenotype of interest
  phen <- c(exposure, outcome)[!c(exposure, outcome) == "methylation"]
  res_file <- paste0(out_path, phen, ".txt")
  if (file.exists(res_file)) return(NULL)
  print(phen)
  
  # read in svs  
  svs <- read_tsv(paste0("data/", cohort_path, "svs/", phen, ".txt"))
  sv_nam <- grep("sv[0-9]", colnames(svs), value = T)

  all_covs <- c(covs, sv_nam)
  sv_out_nam <- paste(length(sv_nam), "surrogate variables")
  all_covs_nam <- paste(cov_nam, sv_out_nam, sep = ", ")

  # Prepare phenotype data
  temp_phen <- pheno_dat %>%
  	dplyr::select(Sample_Name, one_of(phen), one_of(covs)) %>%
  	left_join(svs) %>%
  	na.omit(.)

  # Match meth to Pheno
  temp_meth <- meth_dat[, na.omit(match(temp_phen$Sample_Name, colnames(meth_dat)))]
  temp_phen <- temp_phen[match(colnames(temp_meth), temp_phen$Sample_Name), ]

  if (!all(temp_phen$Sample_Name == colnames(temp_meth))) stop("phenotype and DNAm data not matched.")

  model <- as.formula(paste0(outcome, " ~ ", paste(c(exposure, all_covs), collapse = " + ")))

  # get characteristics for the catalog
  
  age_var <- grep("age", all_covs, value = TRUE, ignore.case = FALSE)
  age_vals <- ifelse(length(age_var) == 1, pheno_dat[[age_var]], NA)
  # output the data needed for EWAS catalog
  out_dat <- get_characteristics(exposure, 
                                 outcome, 
                                 phen,
                                 pheno_dat,
                                 mean(age_vals), 
                                 all_covs_nam)
  # generate study ID
  out_dat$StudyID <- generate_study_id(out_dat)
  # Run EWAS using ewaff
  tryCatch({
      obj <- ewaff.sites(model, variable.of.interest = phen,
      methylation = temp_meth, data = temp_phen, method = "glm", 
      generate.confounders = NULL, family = model_family)

      res <- obj$table %>%
      	rownames_to_column(var = "probeID") %>%
      	dplyr::select(probeID, estimate, se, p.value) %>%
        mutate(Details = NA, StudyID = out_dat$StudyID)

      write.table(res, file = res_file, sep = "\t", col.names = T, row.names = F, quote = F)
      print(paste0("Results for ", phen, " saved."))
  }, error = function(e) {
      print(paste0("Error in EWAS of ", phen, ". Variance of ", phen, " = ", var(temp_phen[[phen]])))
  })
  # return the ewas characteristics
  return(out_dat)
}

out_dir <- paste0("results/", cohort_path, "full_stats/")
char_out <- map_dfr(seq_along(traits), function(x) {
  trait <- traits[x]
  print(x)
  out <- run_ewas(exposure = trait, 
           outcome = "methylation", 
           out_path = out_dir, 
           model_family = "gaussian", 
           meth_dat = meth, 
           pheno_dat = pheno_dat)
  return(out)
})

char_out_nam <- paste0("results/", cohort_path, "catalog_meta_data.txt")
write.table(char_out, file = char_out_nam,
            quote = F, row.names = F, col.names = T, sep = "\t")

