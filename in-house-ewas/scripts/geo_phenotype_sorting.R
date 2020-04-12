# -------------------------------------------------
# Sorting geo phenotypes for EWAS
# -------------------------------------------------

pkgs <- c("tidyverse", "readxl")
lapply(pkgs, require, character.only = TRUE)

source("scripts/read_filepaths.R")

read_filepaths("filepaths.sh")

devtools::load_all("~/repos/usefunc")

phenofile <- "data/geo/ewas-cat-cr02.rdata"
load(phenofile)
# phenofile contains
# all.gses:
#   a d.f, looks like all GSEs and some meta data
# my.gses:
#   a d.f, similar to all.gses but it's filtered and has
#   filenames and pubmed_id 
# ecat.gses:
#   a d.f, similar to all.gses, but with a filtered list of GSEs +
#   lots of columns containing potential phenotype info
# ecats:
#   a d.f, similar to ecat.gses, but with fewer GSEs, unsure why
# ecats.for.print:
#   a d.f, similar to ecats, but with slightly different column names
#   unsure of reason for each
# chrs: 
#   a list of d.fs, each element of the list contains phenotype info
#   for a GSE, looks to be same GSEs as in ecat.gses --> USEFUL
# geo:
#   a list of d.fs, each element of the list contains meta data info
#   for a GSE, looks to be same GSEs as in ecat.gses --> USEFUL


# Manually reviewed to see if analysis could be done
# for the catalog
reviewed_data <- read_excel("data/geo/ewas_cat_gses_for_review.xlsx")
str(reviewed_data)
colnames(reviewed_data)
include_col <- grep("include", colnames(reviewed_data), value = TRUE)
renam_var <- c(include = include_col)

effect_cols <- grep("effect.col.name", colnames(reviewed_data), value = T)

pub_dat <- reviewed_data %>%
    rename(!!renam_var) %>%
    dplyr::filter(include == 2) %>%
    # removal of variables that haven't got anything in
    dplyr::select(which(!map_lgl(., function(x) {all(x == "NA")}))) %>%
    dplyr::select(geo.accession, pubmed_id, main.effect, samples, include, comment,
                  one_of(effect_cols), 
                  one_of(grep("chr.fld", colnames(reviewed_data), value = T)))

# -------------------------------------------------
# Extract trait for the analysis
# -------------------------------------------------

# traits for EWAS
pub_dat$main.effect

nrow(pub_dat) # 50 datasets selected

# extract the phenotypes and sample_names
geo_asc <- pub_dat$geo.accession
phen_list <- lapply(geo_asc, function(ga) {
    all_info <- geo[[ga]]
	pheno <- chrs[[ga]]
    # some files have values as a row rather than a column
    # so this if statement sorts them out
	if (nrow(pheno) == 1) {
        print(ga)
		values <- as.character(pheno[1,])
		phe <- data.frame(values)
		colnames(phe) <- colnames(pheno)[1]
		pheno <- phe
	}
	pheno$sample_name <- rownames(all_info)
	return(pheno)
})
names(phen_list) <- geo_asc

# extract phenotype names
phens <- lapply(phen_list, colnames)



ga <- "GSE36054"
ga <- "GSE100197"
ga <- geo_asc[18]
effect_phen_dat <- lapply(geo_asc, function(ga) {
    print(ga)
    d <- phen_list[[ga]]
    VoI <- pub_dat %>%
        dplyr::filter(geo.accession == ga) %>%
        dplyr::select(one_of(effect_cols)) %>%
        as.character()
    empty_cols <- which(colnames(d) == "")
    for (i in empty_cols) {
        colnames(d)[i] <- paste0("no_name", i)
    }
    d <- d %>%
        dplyr::select(sample_name, one_of(VoI))
    return(d)
})
names(effect_phen_dat) <- geo_asc


# ---------------------------------------
# Check values for each variable
# ---------------------------------------

# check each VoI. Want to check that:
#   1. that the values are as expected
#   2. it needs to be split into different variables
#   3. duplication of samples

# to ask about:
# 1. 
# 3. --> do I split by biopsy region??
# 12. --> can't see age (check phen_list[[geo_asc[12]]])
# 13. --> can't see recurrance and recurrance time variables...
# 17. --> Just do adjacent vs. all the others? (what do the numbers mean??)
# 22. --> comment mentions "multiple datasets", as in multiple GEO datasets???
# 23. --> comment mentions "multiple datasets", as in multiple GEO datasets???
# 26. --> comment mentions should split by cell type. Some cell types have <100 individuals
#         the cell types are just blood cell types, so would SVs account for these differences?
# 28. --> What is the control group?
# 30. --> remove unclassified and bin normal and normal_hepatocyte together?
# 32. --> How is birthweight coded as 0 and 1???
# 36. --> Got 4 ages... Treat as continuous??
# 42. --> what are the scales of the different measurements??
# 46. --> no variable of interest, wtf?!?
# 48. --> comment: "Paper used a discovery and replication cohort, so need to check numbers to see if they have uploaded the data for both. Clearly no column to help define them though"

# checking the phenotypes!
ga <- geo_asc[1]
pub_dat[pub_dat$geo.accession == ga, "comment", drop = T]
effect_phen_dat[ga]
str(effect_phen_dat[ga])
table(effect_phen_dat[[ga]][[2]])

omit_for_now <- c(1,3,12,13,17,22,23,26,28,30,32,36,42,46,48)
effect_phen_dat <- effect_phen_dat[-omit_for_now]

geo_asc <- names(effect_phen_dat)
# check there are no duplicated samples
map_lgl(geo_asc, function(ga) {
    some_dat <- effect_phen_dat[[ga]]
    any(duplicated(some_dat[["sample_name"]]))
})
# all goooooood boi! 

# ---------------------------------------
# manual changes to the datasets to revalue the variables
# ---------------------------------------

# changes to make
effect_phen_dat[["GSE107080"]] <- effect_phen_dat[["GSE107080"]] %>%
    mutate(idu_and_hcv_dx = case_when(idu == 1 & hcv_dx == 1 ~ "pos", 
                                      idu == 0 & hcv_dx == 0 ~ "neg")) %>%
    dplyr::filter(!is.na(idu_and_hcv_dx)) %>%
    dplyr::select(sample_name, idu_and_hcv_dx)

effect_phen_dat[["GSE112596"]] <- effect_phen_dat[["GSE112596"]] %>%
    dplyr::filter(therapy != "GA")

effect_phen_dat[["GSE113725"]] <- effect_phen_dat[["GSE113725"]] %>%
    mutate(depression_status = case_when(groupid == 1 | groupid == 2 ~ "control", 
                                         groupid == 3 | groupid == 4 ~ "case")) %>%
    dplyr::select(sample_name, depression_status)

effect_phen_dat[["GSE50660"]] <- effect_phen_dat[["GSE50660"]] %>% 
    mutate(smoking_status_nf = 
        case_when(`smoking (0, 1 and 2, which represent never, former and current smokers)` == 0 ~ "never", 
                  `smoking (0, 1 and 2, which represent never, former and current smokers)` == 1 ~ "former")) %>%
    mutate(smoking_status_nc = 
        case_when(`smoking (0, 1 and 2, which represent never, former and current smokers)` == 0 ~ "never", 
                  `smoking (0, 1 and 2, which represent never, former and current smokers)` == 2 ~ "current")) %>%
    mutate(smoking_status_fc = 
        case_when(`smoking (0, 1 and 2, which represent never, former and current smokers)` == 1 ~ "former", 
                  `smoking (0, 1 and 2, which represent never, former and current smokers)` == 2 ~ "current")) %>%
    dplyr::select(-`smoking (0, 1 and 2, which represent never, former and current smokers)`)

effect_phen_dat[["GSE53740"]] <- effect_phen_dat[["GSE53740"]] %>%
    mutate(FTD_status = case_when(diagnosis == "FTD" ~ "FTD", 
                                  diagnosis == "Control" ~ "Control")) %>%
    mutate(PSP_status = case_when(diagnosis == "PSP" ~ "PSP", 
                                  diagnosis == "Control" ~ "Control")) %>%
    dplyr::select(-diagnosis)

effect_phen_dat[["GSE59592"]] <- effect_phen_dat[["GSE59592"]] %>%
    dplyr::filter(!(`afb1 exposure` %in% c("dry", "rainy")))

effect_phen_dat[["GSE60275"]] <- effect_phen_dat[["GSE60275"]] %>%
    dplyr::filter(healthy_vs_disease != "healthy")

effect_phen_dat[["GSE67530"]] <- effect_phen_dat[["GSE67530"]] %>%
    dplyr::filter(ards != "NA")

effect_phen_dat[["GSE69502"]] <- effect_phen_dat[["GSE69502"]] %>% 
    mutate(anencephaly_status = case_when(`ntd status` == "anencephaly" ~ "anencephaly", 
                                          `ntd status` == "control" ~ "control")) %>% 
    mutate(spina_bifida_status = case_when(`ntd status` == "spina bifida" ~ "spina_bifida", 
                                           `ntd status` == "control" ~ "control")) %>%
    dplyr::select(-`ntd status`)

effect_phen_dat[["GSE71678"]] <- effect_phen_dat[["GSE71678"]] %>%
    dplyr::filter(`placental as levels` != "NA")

effect_phen_dat[["GSE87640"]] <- effect_phen_dat[["GSE87640"]] %>% 
    mutate(UC_diagnosis = case_when(full_diagnosis == "UC" ~ "UC",
                                    full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    mutate(CD_diagnosis = case_when(full_diagnosis == "CD" ~ "CD", 
                                    full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    mutate(IBD_diagnosis = case_when(full_diagnosis %in% c("CD", "UC") ~ "IBD", 
                                     full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    dplyr::select(-full_diagnosis)

# ---------------------------------------
# extract some useful meta data from datasets
# ---------------------------------------

# sort out names + add meta data then write out the results! 
nam="GSE40279"
met_dat <- lapply(names(effect_phen_dat), function(nam) {
    print(nam)
    df <- effect_phen_dat[[nam]]
    pubmid <- pub_dat %>%
        dplyr::filter(geo.accession == nam) %>%
        pull(pubmed_id)
    old_effect_nam <- colnames(df)[colnames(df) != "sample_name"]
    out_dat <- map_dfr(old_effect_nam, function(oen) {
        new_effect_nam <- tolower(gsub("[[:space:]]", "_", oen)) 
        new_effect_nam <- gsub('[[:punct:]]', '_' , new_effect_nam)
        bin <- is.binary(df[[oen]])
        out <- tibble(geo_asc = nam, 
                     pmid = pubmid, 
                     phen = new_effect_nam, 
                     binary = bin, 
                     unedited_label = oen, 
                     n = nrow(df))
        return(out)
    })
    return(out_dat)
})
names(met_dat) <- geo_asc

# for meta-data, the actual name of the trait will
# need to be mannually edited using the review file

# ------------------------------------------------------
# clean data
# ------------------------------------------------------

# set outliers to missing
set_outliers_to_na <- function(x) {
    q <- quantile(x, probs = c(0.25, 0.75), na.rm = T)
    iqr <- q[2] - q[1]
    too_hi <- which(x > q[2] + 3 * iqr)
    too_lo <- which(x < q[1] - 3 * iqr)
    if (length(c(too_lo,too_hi)) > 0) x[c(too_lo, too_hi)] <- NA
    return(x)
}

no_out_phen <- lapply(geo_asc, function(ga) {
    print(ga)
    df <- effect_phen_dat[[ga]]
    # if binary then give it a miss
    met_df <- met_dat[[ga]]
    cols <- colnames(df)
    out_dat <- map_dfc(cols, function(trait) {
        var <- df[[trait]]
        # return variable if sample_name or binary
        if (trait %in% "sample_name") return(var)
        bin_val <- met_df[met_df$unedited_label == trait, "binary"]
        if (bin_val == TRUE) return(var)

        var <- as.numeric(var)
        out <- set_outliers_to_na(var)
        total_vals <- sum(!is.na(out))
        new_na <- sum(is.na(out)) - sum(is.na(var))
        message(new_na, " values set to missing for ", trait)
        message(total_vals, " non missing values remain for ", trait)
        return(out)
    })
    colnames(out_dat) <- cols
    return(out_dat)
})
names(no_out_phen) <- geo_asc
# doesn't seem to be removal of many values!

# check zero values
count_zero <- lapply(geo_asc, function(ga) {
    print(ga)
    df <- no_out_phen[[ga]]
    # if binary then give it a miss
    met_df <- met_dat[[ga]]
    count_zero <- map_dbl(1:nrow(met_df), function(x) {
        bin <- met_df[x, "binary", drop = TRUE]
        if (bin) return(NA)
        col <- met_df[x, "unedited_label", drop = TRUE]
        sum(df[[col]] == 0, na.rm = T)
    })
    names(count_zero) <- met_df$unedited_label
    return(count_zero)
})
# only phenotype with any zeros is total body naevus count,
# which makes total sense! 

fin_dat <- no_out_phen

# ------------------------------------------------------
# write out the data!
# ------------------------------------------------------

make_dir <- function(path) {
    system(paste("mkdir", path))
}

# write out cleaned phenotype data and meta data
lapply(geo_asc, function(ga) {
    meta_dat <- met_dat[[ga]]
    
    # rename variables as appropriate
    pheno_dat <- fin_dat[[ga]] %>%
        rename_at(vars(meta_dat$unedited_label), ~ meta_dat$phen)

    out_path <- file.path("data/geo", ga)

    if (!file.exists(out_path)) make_dir(out_path)

    meta_nam <- file.path(out_path, "phenotype_metadata.txt")
    write.table(meta_dat, file = meta_nam,
                col.names = T, row.names = F, quote = F, sep = "\t")
    
    pheno_nam <- file.path(out_path, "cleaned_phenotype_data.txt")
    write.table(pheno_dat, file = pheno_nam,
                col.names = T, row.names = F, quote = F, sep = "\t")
    return(NULL)
})

# write out geo accession numbers being used
write.table(geo_asc, file = "data/geo/geo_accession.txt", 
            col.names = F, row.names = F, quote = F, sep = "\t")

