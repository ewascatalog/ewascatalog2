# -------------------------------------------------
# Sorting geo phenotypes for EWAS
# -------------------------------------------------

rm(list = ls())

wd <- "~/ewas_catalog/"
setwd(wd)

pkgs <- c("tidyverse", "haven", "readxl", "gridExtra")
lapply(pkgs, require, character.only = TRUE)

devtools::load_all("~/repos/usefunc")
devtools::load_all("~/repos/ewaff")

phenofile <- "~/ewas_catalog/geo_data/ewas-cat-cr02.rdata"
load(phenofile)

# GSEs reviewed
reviewed_data <- read_excel("ewas_cat_gses_for_review.xlsx")
str(reviewed_data)

dat <- reviewed_data %>%
    mutate(include = .[[grep("include", colnames(.))]]) %>%
    dplyr::filter(include == 2) %>%
    # removal of variables that haven't got anything in
    dplyr::select(which(!map_lgl(., function(x) {all(x == "NA")}))) %>%
    dplyr::select(geo.accession, main.effect, samples, include, comment, 
                  one_of(grep("chr.fld", colnames(reviewed_data), value = T)))

dat$main.effect

# extract the phenotypes and sample_names
geo_asc <- dat$geo.accession
phen_list <- lapply(geo_asc, function(ga) {
	all_info <- geo[[ga]]
	pheno <- chrs[[ga]]
	if (nrow(pheno) == 1) {
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
phens <- lapply(geo_asc, function(ga) {
	colnames(phen_list[[ga]])	
})
names(phens) <- geo_asc
voi_file <- "current_voi_list.RData"
if (file.exists(voi_file)) {
    load(voi_file)
    old_VoI_list <- VoI_list
} else {
    VoI_list <- list()
}

new_phens <- phens[!names(phens) %in% names(old_VoI_list)]
dat %>%
    dplyr::filter(geo.accession %in% names(new_phens)) %>%
    .[["main.effect"]]
# extract rest of variables
new_VoI_list <- list()

names(new_VoI_list) <- names(new_phens)
VoI_list <- c(new_VoI_list, old_VoI_list)

VoI_list <- VoI_list[match(dat$geo.accession, names(VoI_list))]

if (length(new_VoI_list) != 0) save(VoI_list, file = "current_voi_list.RData") 

# need to find out wtf matt is talking about 
# re: recurrence and recurrence time

# want to have a finished list with the variables of interest
# and sample_name in a column each and with any values that are useless
# removed 

ga <- "GSE36054"
fin_dat <- lapply(geo_asc, function(ga) {
    print(ga)
    VoI <- VoI_list[[ga]]
    print(VoI)
    if (is.na(VoI)) return(NULL)
    d <- phen_list[[ga]]
    empty_cols <- which(colnames(d) == "")
    for (i in empty_cols) {
        colnames(d)[i] <- paste0("no_name", i)
    }
    d <- d %>%
        dplyr::select(sample_name, one_of(VoI))
    return(d)
})
names(fin_dat) <- geo_asc
# check each VoI. Want to check that:
#   1. if continuous, distribution is normal
#   2. that the values are as expected
#   3. it needs to be split into different variables
#   4. sample size is above 100
#   5. duplication of samples

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
dat[dat$geo.accession == ga, "comment", drop = T]
fin_dat[ga]
str(fin_dat[ga])
table(fin_dat[[ga]][[2]])

omit_for_now <- c(1,3,12,13,17,22,23,26,28,30,32,36,42,46,48)

# check there are no duplicated samples
map_lgl(geo_asc, function(ga) {
    some_dat <- fin_dat[[ga]]
    any(duplicated(some_dat[["sample_name"]]))
})
# all goooooood boi! 

# changes to make
fin_dat[["GSE107080"]] <- fin_dat[["GSE107080"]] %>%
    mutate(idu_and_hcv_dx = case_when(idu == 1 & hcv_dx == 1 ~ "pos", 
                                      idu == 0 & hcv_dx == 0 ~ "neg")) %>%
    dplyr::filter(!is.na(idu_and_hcv_dx)) %>%
    dplyr::select(sample_name, idu_and_hcv_dx)

fin_dat[["GSE112596"]] <- fin_dat[["GSE112596"]] %>%
    dplyr::filter(therapy != "GA")

fin_dat[["GSE113725"]] <- fin_dat[["GSE113725"]] %>%
    mutate(depression_status = case_when(groupid == 1 | groupid == 2 ~ "control", 
                                         groupid == 3 | groupid == 4 ~ "case")) %>%
    dplyr::select(sample_name, depression_status)

fin_dat[["GSE50660"]] <- fin_dat[["GSE50660"]] %>% 
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

fin_dat[["GSE53740"]] <- fin_dat[["GSE53740"]] %>%
    mutate(FTD_status = case_when(diagnosis == "FTD" ~ "FTD", 
                                  diagnosis == "Control" ~ "Control")) %>%
    mutate(PSP_status = case_when(diagnosis == "PSP" ~ "PSP", 
                                  diagnosis == "Control" ~ "Control")) %>%
    dplyr::select(-diagnosis)

fin_dat[["GSE59592"]] <- fin_dat[["GSE59592"]] %>%
    dplyr::filter(!(`afb1 exposure` %in% c("dry", "rainy")))

fin_dat[["GSE60275"]] <- fin_dat[["GSE60275"]] %>%
    dplyr::filter(healthy_vs_disease != "healthy")

fin_dat[["GSE67530"]] <- fin_dat[["GSE67530"]] %>%
    dplyr::filter(ards != "NA")

fin_dat[["GSE69502"]] <- fin_dat[["GSE69502"]] %>% 
    mutate(anencephaly_status = case_when(`ntd status` == "anencephaly" ~ "anencephaly", 
                                          `ntd status` == "control" ~ "control")) %>% 
    mutate(spina_bifida_status = case_when(`ntd status` == "spina bifida" ~ "spina_bifida", 
                                           `ntd status` == "control" ~ "control")) %>%
    dplyr::select(-`ntd status`)

fin_dat[["GSE71678"]] <- fin_dat[["GSE71678"]] %>%
    dplyr::filter(`placental as levels` != "NA")

fin_dat[["GSE87640"]] <- fin_dat[["GSE87640"]] %>% 
    mutate(UC_diagnosis = case_when(full_diagnosis == "UC" ~ "UC",
                                    full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    mutate(CD_diagnosis = case_when(full_diagnosis == "CD" ~ "CD", 
                                    full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    mutate(IBD_diagnosis = case_when(full_diagnosis %in% c("CD", "UC") ~ "IBD", 
                                     full_diagnosis %in% c("HC", "HL", "IB", "OT") ~ "healthy")) %>%
    dplyr::select(-full_diagnosis)

# check distribution of continuous variables
dist_check <- list(
    GSE101961 = fin_dat[["GSE101961"]][[2]], 
    GSE40279 = fin_dat[["GSE40279"]][[2]], 
    GSE51057 = fin_dat[["GSE51057"]][[2]], 
    GSE58885 = fin_dat[["GSE58885"]][[2]], 
    GSE59592 = fin_dat[["GSE59592"]][[2]], 
    GSE71678 = fin_dat[["GSE71678"]][[2]], 
    GSE90124 = fin_dat[["GSE90124"]][[2]]
    )

plots <- lapply(dist_check, function(v) {
    df <- data.frame(var = as.numeric(v))
    p <- ggplot(df, aes(x = var)) + 
        geom_histogram()
})

pdf("geo_continuous_var_distributions.pdf")
p <- marrangeGrob(plots, ncol=1, nrow=1)
dev.off()
ggsave("geo_continuous_var_distributions.pdf", plot = p)

# right-skew with:
# GSE59592
# GSE71678
# GSE90124
rs <- c("GSE59592", "GSE71678", "GSE90124")

# GSE90124 looks like count data so can use a poisson distribution to model it
pois_mod <- "GSE90124"
# log and try again:
log_plots <- lapply(dist_check[rs], function(v) {
    df <- data.frame(var = log(as.numeric(v)))
    p <- ggplot(df, aes(x = var)) +
        geom_histogram()
})
pdf("geo_continuous_var_distributions_logged.pdf")
p <- marrangeGrob(log_plots, ncol=1, nrow=1)
dev.off()
ggsave("geo_continuous_var_distributions_logged.pdf", plot = p)

# all normal now! --> Transform those bad bois
to_log <- rs[-3]
fin_dat[rs[-3]] <- lapply(to_log, function(x) {
    dat <- fin_dat[[x]]
    dat[[2]] <- log(as.numeric(dat[[2]]))
    return(dat)
})

# sort the names of all the phenotypes! 
nam="GSE40279"
fin_dat <- lapply(names(fin_dat), function(nam) {
    print(nam)
    df <- fin_dat[[nam]]
    if (class(df) != "data.frame") return(df)
    colnames(df) <- tolower(gsub("[[:space:]]", "_", colnames(df)))
    colnames(df) <- gsub('[[:punct:]]', '_' , colnames(df))

    return(df)
})
names(fin_dat) <- geo_asc

inclusion_df <- tibble(geo_asc = names(fin_dat),
                       include = ifelse(geo_asc %in% geo_asc[omit_for_now], "no", "yes"), 
                       model = ifelse(geo_asc %in% pois_mod, "poisson", "as_expect"), 
                       transformed = ifelse(geo_asc %in% to_log, "log", "no"))

to_save <- list(pheno_data = fin_dat, inclusion_data = inclusion_df)
save(to_save, file = "geo_data/derived/sorted_geo_phenotype_data.RData")

# ---------------------------------------------------------------
# Post attempted analysis phenotype sorting
# ---------------------------------------------------------------
load("geo_data/derived/sorted_geo_phenotype_data.RData")
inclusion_data <- to_save[["inclusion_data"]]
pheno_data <- to_save[["pheno_data"]]
geo_asc <- names(pheno_data)

epic_array <- c("GSE112596", "GSE107080", "GSE118144")
failed_sv <- "GSE80261"

pheno_data <- pheno_data[epic_array]
str(pheno_data)

un_sorted_phenofile <- "~/ewas_catalog/geo_data/ewas-cat-cr02.rdata"
load(un_sorted_phenofile)

# ---------------------------------------------------
# cleaning first epic array dataset
# ---------------------------------------------------
ga <- epic_array[1]
all_info <- geo[[ga]]
str(all_info)
meth_file <- paste0(tolower(ga), ".rda")
load(paste0("geo_data/", meth_file))
meth <- x
colnames(meth)

# colnames look very similar to all_info$title...
cols <- gsub("-", ".", all_info$title)
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$ID
meth <- meth[, -1] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data (from previous cleaning, see above!)
meth <- meth[, colnames(meth) %in% pheno_data[[ga]][["sample_name"]]]

# save the old version of the meth data
save(x, file = paste0("geo_data/old_data/", meth_file))
# save the new data, ready for an EWAS! 
save(meth, file = paste0("geo_data/", meth_file))

# ---------------------------------------------------
# cleaning second epic array dataset
# ---------------------------------------------------
ga <- epic_array[2]
all_info <- geo[[ga]]
str(all_info)
meth_file <- paste0(tolower(ga), ".rda")
load(paste0("geo_data/", meth_file))
meth <- x
colnames(meth)

# colnames look similar to all_info$description.2
cols <- gsub(" ", ".", all_info$description.2)
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$ID_REF
meth <- meth[, -1] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data (from previous cleaning, see above!)
meth <- meth[, colnames(meth) %in% pheno_data[[ga]][["sample_name"]]]

# save the old version of the meth data
save(x, file = paste0("geo_data/old_data/", meth_file))
# save the new data, ready for an EWAS! 
save(meth, file = paste0("geo_data/", meth_file))


# ---------------------------------------------------
# cleaning third epic array dataset
# ---------------------------------------------------
ga <- epic_array[3]
all_info <- geo[[ga]]
str(all_info)
meth_file <- paste0(tolower(ga), ".rda")
load(paste0("geo_data/", meth_file))
meth <- x
colnames(meth)

# colnames look similar to all_info$title
cols <- paste(gsub(":.*", "", all_info$title), "AVG_Beta", sep = ".")
colnames(meth)

# cpgs are listed under "ID" column --> change to rownames
rownames(meth) <- meth$TargetID
meth <- meth[, -1] 
meth <- meth[, cols] # This removed a load of columns, but these were all "p < x" so clearly not beta values

# change the colnames out for the geo accessions! 
index <- match(cols, colnames(meth))
meth <- meth[, index]
all(colnames(meth) == cols)
colnames(meth) <- all_info$geo_accession

# now just take out the unnecessary data (from previous cleaning, see above!)
meth <- meth[, colnames(meth) %in% pheno_data[[ga]][["sample_name"]]]

# save the old version of the meth data
save(x, file = paste0("geo_data/old_data/", meth_file))
# save the new data, ready for an EWAS! 
save(meth, file = paste0("geo_data/", meth_file))







