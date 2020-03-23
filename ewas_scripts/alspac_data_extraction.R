# -------------------------------------------------------
# Extracting ALSPAC data
# -------------------------------------------------------

# requirements for this script to work:
# 1. need IDs for people in ARIES
# 2. need Tom's version of alspac package: github.com/thomasbattram/alspac
#    (made pull request with main package, but not accepted...)
# 3. access to alspac data (duhhh)

args <- commandArgs(trailingOnly = TRUE)
wd <- args[1]
alspac_data_dir <- args[2]
output_path <- args[3]
aries_ids <- args[4]
timepoints <- args[5]
password <- args[6]
message("working directory is: ", wd)
message("alspac data directory is: ", alspac_data_dir)
message("the ouput path is: ", output_path)
message("the ARIES ID file is: ", aries_ids)
message("timepoints are: ", timepoints)
setwd(wd)
stopifnot(file.exists(output_path))
stopifnot(file.exists(alspac_data_dir))
stopifnot(file.exists(aries_ids))

pkgs <- c("alspac", "tidyverse", "haven", "readxl")
lapply(pkgs, require, character.only = T)
setDataDir(alspac_data_dir)

# devtools::load_all("")
# devtools::load_all("") # not sure if works!!!

data(current)
data(useful)

# -------------------------------------------------------
# RUN THIS TO UPDATE THE DICTIONARIES
# -------------------------------------------------------
# current <- createDictionary("Current", name="current")
# useful <- createDictionary("Useful_data", name="useful")

# -------------------------------------------------------
# Filter out data not present enough in ARIES
# -------------------------------------------------------

# Read in the ARIES IDs and extract ones from timepoint of interest
IDs <- read_tsv(aries_ids)
IDs <- dplyr::filter(IDs, time_point == timepoints)
str(IDs)

# -------------------------------------------------------
# extraction setup
# -------------------------------------------------------

if ("FOM" %in% timepoints) {
	tim_dat <- "FOM1"
	file <- "FOM1_3a.dta"
}

new_current <- current %>%
	dplyr::filter(obj %in% file)

# paths of interest
# PoI <- c()

labs_to_na <- function(x) {
	labs <- attr(x, "labels")
	x[x %in% labs] <- NA
	return(x)
}

# ------------------------------------------------------------------------------------
# Extract data 
# ------------------------------------------------------------------------------------
# Questionairre data
result <- extractVars(new_current)

## finding the age of participants at each questionnaire

mult_cols <- grep("mult", colnames(result), value = T)

res <- result[, !(colnames(result) %in% mult_cols)]
dim(new_current)
dup_names <- new_current[duplicated(new_current$name), "name"]
# just aln is duplicated! 
new_current <- dplyr::filter(new_current, name %in% colnames(res)) %>%
	filter(!duplicated(name))

head(new_current)
head(colnames(res))
grep("aln|qlet", colnames(res))
dim(res)
dim(new_current)
test_res <- res[,colnames(res)[!colnames(res) %in% new_current$name]]
# delete extra columns minus the aln, qlet and alnqlet columns
col_rm <- colnames(res)[!colnames(res) %in% new_current$name]
col_rm <- col_rm[!col_rm %in% c("qlet", "alnqlet")]
res <- res[,!colnames(res) %in% col_rm]
qlet_cols <- grep("qlet", colnames(res), value = T)
str(test_res)
# Change the column names to phenotypes
index <- match(colnames(res)[!colnames(res) %in% qlet_cols], new_current$name)
new_current2 <- new_current[index, ]
# res <- res[, c(1, index)]
# res[1:10, 1:10]
# Sanity check

stopifnot(all(new_current2$name == colnames(res[, !colnames(res) %in% qlet_cols])))
sum(new_current2$name == colnames(res[, !colnames(res) %in% qlet_cols]))

dim(new_current2)
new_labs <- gsub(" ", "_", new_current2$lab)
colnames(res)[!colnames(res) %in% qlet_cols] <- new_labs
colnames(res)[1] <- "aln"
res[1:10, 1:10]
colnames(res)[colnames(res) == ""] <- "UNNAMED_VAR"
# ------------------------------------------------------------------------------------
# extracting age of participant for each questionnaire
# ------------------------------------------------------------------------------------
grep("_age_", colnames(res), value = T, ignore.case = T)
age_info <- c("Mother's_age_on_completion_of_questionnaire", 
	# "NAT_mothers_age_at_birth",  -- means age of Mum's mum
	# "Nat_mothers_age_now",  -- means age of Mum's mum
	"DV:_Maternal_age_in_years_at_completion_of_'Your_Pregnancy'_questionnaire:_C_fil", 
	# "Age_at_attendance_(years):_FOF1", -- Dad's age
	"Age_at_attendance_(years):_FOM1",
	"Age_at_attendance_(years):_FOM2",
	"Age_at_attendance_(years):_FOM3",
	"Age_at_attendance_(years):_FOM4",
	"Age_participant_had_BCG_(years):_FOM4",
	"Age_of_child_at_completion_(months)",
	"DV:_Age_of_child_at_completion_(months)",
	"DV:_Age_of_child_at_completion_(weeks)",
	"DV:_Assumptions_made_in_calculating_child's_age_at_completion",
	"DV:_Age_of_mother_at_completion_(years)",
	"DV:_Age_of_Mother_At_Completion_(Years)",
	"Age_of_Child_At_Completion_(Years)",
	"DV:_Age_of_study_child_at_completion_(months)", 
	"DV:_Age_of_study_child_at_completion_(weeks)", 
	"DV:_Age_of_respondent_at_completion_of_questionnaire_(years)", 
	"DV:_Age_of_study_child_at_completion_of_questionnaire_(months)", 
	"DV:_Age_of_study_child_at_completion_of_questionnaire_(weeks)", 
	"DV:_Age_of_respondent_at_completion_of_questionnaire_(years)", 
	"DV:_Age_of_study_child_at_completion_(months)", 
	"DV:_Age_of_study_child_at_completion_(weeks)", 
	"DV:_Age_of_respondent_at_completion_of_questionnaire_(years)", 
	"DV:_Age_of_study_child_at_completion_(months)", 
	"DV:_Age_of_study_child_at_completion_(weeks)", 
	"DV:_Age_of_Mother_At_Completion_(Years)", 
	"DV:_Age_of_study_child_at_completion_(months)", 
	"DV:_Age_of_study_child_at_completion_(weeks)", 
	"DV:_Age_of_respondent_at_completion_of_questionnaire_(years)", 
	"DV:_Age_of_study_child_at_completion_(months)", 
	"DV:_Age_of_study_child_at_completion_(weeks)", 
	"DV:_Age_of_respondent_at_completion_of_questionnaire_(years)", 
	"DV:_Age_of_study_child_at_completion_(months)", 
	"DV:_Age_of_study_child_at_completion_(weeks)",
	"DV:_Age_of_respondent_at_completion_of_questionnaire_(years)", 
	"DV:_Age_of_study_child_at_completion_(months)",
	"DV:_Age_of_study_child_at_completion_(weeks)", 
	"DV:_Age_of_study_child_at_completion_(years)", 
	"DV:_YP's_age_in_years_at_time_questionnaire_was_completed", 
	"DV:_Mothers_age_in_years_at_time_questionnaire_was_completed", 
	"DV:_Age_of_study_child_at_completion_(months)", 
	"DV:_Age_of_study_child_at_completion_(weeks)", 
	"DV:_Age_of_carer_at_completion_(years)", 
	"DV:_Age_of_study_child_at_telephone_interview_(months)", 
	"DV:_Age_of_study_child_at_telephone_interview_(weeks)", 
	"DV:_Age_of_carer_at_telephone_interview_(years)",
	"DV:_F1_F2:_Maternal_age_in_years_at_completion_of__'About_Yourself'_questionnair", 
	"DV:_H1_H2:_Maternal_age_in_years_at_completion_of_'Me_and_My_Baby'_questionnaire", 
	"DV:_N2_N3:_Maternal_age_in_years_at_completion_of_'Caring_for_a_Toddler'_questio", 
	"DV:_Mothers_age_in_years_at_time_questionnaire_was_completed"
	)
age_info <- age_info[!duplicated(age_info)]

str(res[,1:10])

count <- 0
for (i in 1:ncol(res)) {
	nam <- colnames(res)[i]
	if (nam %in% qlet_cols) next
	count <- count + 1
	attr(res[[i]], "obj") <- new_current2$obj[count]
	attr(res[[i]], "name") <- new_current2$name[count]
}

res_age <- res[, colnames(res) %in% c("aln", age_info)]
obj_vector <- map_chr(1:ncol(res_age), function(x) attr(res_age[[x]], "obj") )

unique(new_current2$obj)[!(unique(new_current2$obj) %in% obj_vector)]

x <- colnames(res_age)
child_age_vars <- x[grep("child|YP", x, ignore.case = T)]
res_age_ad <- res_age %>%
	dplyr::select(-one_of(child_age_vars))

obj_vector2 <- map_chr(1:ncol(res_age_ad), function(x) attr(res_age_ad[[x]], "obj") )
all(obj_vector2 %in% obj_vector)

no_age_obj <- unique(new_current2$obj)[!(unique(new_current2$obj) %in% obj_vector2)]

res_age_ad %>% 
	dplyr::filter(aln %in% IDs$ALN) -> res_age_ad
### now we have the ages of the Mums at each questionnaire etc.
# can take the age of a few mums at all questionnaire timepoints and with DNAm data and see how it varies!
for (i in seq_along(res_age_ad)) {
	res_age_ad[, i] <- labs_to_na(res_age_ad[, i])
}
count_na <- function(dat, col_or_row = 2) {
	stopifnot(col_or_row %in% c(1,2))
	x <- apply(dat, col_or_row, function(x) {sum(is.na(x))})
	return(x)
}
count_na(res_age_ad) # all of one cat = NA!

res_age_ad <- res_age_ad[complete.cases(res_age_ad),]
age_and_obj <- as.data.frame(t(res_age_ad)) %>%
	rownames_to_column(var = "trait") %>%
	mutate(obj = obj_vector2)

fom_diff <- vector(mode = "numeric", length = nrow(age_and_obj) - 1)
fom_diff <- data.frame(obj = NA, age_diff = NA)
i=2
for (i in 2:(nrow(age_and_obj))) {
	temp <- age_and_obj[i, -c(1,ncol(age_and_obj))] - age_and_obj[age_and_obj$obj == "FOM1_3a.dta", -c(1,ncol(age_and_obj))]
	temp2 <- mean(as.numeric(temp[1,]))
	fom_diff[i-1, "age_diff"] <- round(temp2)
	fom_diff[i-1, "obj"] <- age_and_obj[i,"obj"]
}
# remove the bcg age and one of the telephone interview ages:
fom_diff <- fom_diff[-c(9, 23), ] # CHECK THIS IS STILL CORRECT

# ------------------------------------------------------------------------------------
# removing duplicated column names!
# ------------------------------------------------------------------------------------
dup_labs <- colnames(res)[duplicated(colnames(res))] # need to come back to these if we want repeated measures!
i=dup_labs[1]
for (i in dup_labs) {
	temp_res <- res[, grep(paste0(i, "$"), colnames(res))]
	colnames(temp_res) <- rep(colnames(temp_res)[1], ncol(temp_res))

	for (j in seq_along(temp_res)) {
		colnames(temp_res)[j] <- paste0(colnames(temp_res)[j], "_", attr(temp_res[, j], "name"))
	}
}
res <- res[, !duplicated(colnames(res))]
res <- res %>%
	dplyr::filter(aln %in% IDs$ALN)

# ------------------------------------------------------------------------------------
# Sorting binary vals
# ------------------------------------------------------------------------------------
uniq_vals <- sapply(res, function(x) {length(unique(x[!is.na(x)]))})
uniq_val_2 <- which(uniq_vals == 2)
uniq_val_3 <- which(uniq_vals == 3)

length(uniq_val_3)
length(uniq_val_2)

res_bin <- res[, colnames(res) %in% names(uniq_val_2) | colnames(res) %in% names(uniq_val_3)]
res <- res[, !(colnames(res) %in% colnames(res_bin))]

dim(res)
for (i in seq_along(res)) {
	res[, i] <- labs_to_na(res[, i])
}



# non-binary vars
# non_bin <- which(uniq_vals > 3)
# pot_cat <- which(uniq_vals[non_bin] < 10) # potentially categorical
# length(pot_cat)
# pot_cat
# hist(uniq_vals[names(uniq_vals) %in% names(pot_cat)])

# res_sav <-res 
# res <- res[, to_keep] %>%
# 	filter(aln %in% IDs$ALN)
# test <- sapply(res, function(x) {length(unique(x[!is.na(x)]))})
# table(test)
# Removal of categories where there are <100 values
missing <- sapply(res, function(x) {sum(is.na(x))})
names(missing)
vars_rm <- missing[missing > (nrow(res) - 100)]
length(vars_rm) # 8437 variables removed due to lack of people
res2 <- dplyr::select(res, -one_of(names(vars_rm)))
dim(res2)

factors <- sapply(res2, function(x){is.factor(x)})
sum(factors) ## 0 factors!!!! 

res3 <- res2

vals <- lapply(res_bin, function(x) {unique(x)})
un_vals <- unlist(vals)
bin_vals <- data.frame(variable = names(un_vals), value = un_vals)
bin_vals$variable <- gsub("[[:digit:]]$", "", bin_vals$variable)
rownames(bin_vals) <- NULL
table(bin_vals$value)
# now we need the objects they're in to get what the codes mean!!!
bin_labs <- lapply(res_bin, function(x) {attr(x, "labels")})

bin_labs_list <- list()
i=1
for (i in seq_along(bin_labs)) {
	temp_var <- names(bin_labs[i])
	temp_val <- bin_labs[[i]]
	temp_lab <- names(bin_labs[[i]])
	temp_bin_labs_df <- data.frame(variable = rep(temp_var, times = length(temp_val)), value = temp_val, label = temp_lab)

	bin_labs_list[[i]] <- temp_bin_labs_df
}

bin_labs_df <- do.call(rbind, bin_labs_list)
rownames(bin_labs_df) <- NULL

str(res_bin[,1:10])
#### Now need to go through each of these variables and check number of labels to see if categorical or binary! 
i=1
bin_lab_list <- list()
for (i in seq_along(res_bin)) {
	temp_var <- colnames(res_bin)[i]
	temp_bin_labs <- bin_labs_df %>%
		dplyr::filter(variable %in% temp_var)
	temp_res <- res_bin %>%
		dplyr::select(one_of(temp_var))
	# deal with vars that have -1 in --> if it's missing then assign to NA and remove from bin_labs?
	if (-1 %in% temp_bin_labs$value) {
		res_bin[[temp_var]][res_bin[[temp_var]] == -1] <- NA
		temp_bin_labs <- temp_bin_labs %>%
			dplyr::filter(value != -1)
	}
	# deal with vars that have -9999 in --> if consent withdrawn then assign to NA and remove from bin_;abs?
	if (-9999 %in% temp_bin_labs$value) {
		temp_bin_labs <- temp_bin_labs %>%
			dplyr::filter(value != -9999)
	}
	# deal with vars that have -7 in (YE short) --> set to NA and remove from bin_labs -----> CHECK THIS VALUE!!!
	if (-7 %in% temp_bin_labs$value) {
		res_bin[[temp_var]][res_bin[[temp_var]] == -7] <- NA
		temp_bin_labs <- temp_bin_labs %>%
			dplyr::filter(value != -7)
	}
	if (nrow(temp_bin_labs) > 0) {
		if (c(1,2) == temp_bin_labs$value) {
			temp_bin_labs[["bin_or_cat"]] <- "bin"
		} else {
			temp_bin_labs[["bin_or_cat"]] <- "cat"		
		}
	}
	bin_lab_list[[i]] <- temp_bin_labs
}
fin_bin_lab <- do.call(rbind, bin_lab_list)

defo_bin <- fin_bin_lab %>%
	dplyr::filter(bin_or_cat == "bin")
length(unique(defo_bin$variable)) # 1150
pot_cat <- fin_bin_lab %>%
	dplyr::filter(bin_or_cat == "cat")
length(unique(pot_cat$variable)) # 2080

# ------------------------------------------------------------------------------------
# checking potentially binary variables that are labelled as categorical
# ------------------------------------------------------------------------------------

cat_vars <- vector(mode = "numeric", length = length(unique(pot_cat$variable)))
names(cat_vars) <- as.character(unique(pot_cat$variable))
i=unique(as.character(pot_cat$variable))[1]
for (i in unique(as.character(pot_cat$variable))) {
	temp_pot <- dplyr::filter(pot_cat, variable == i)
	cat_vars[[i]] <- nrow(temp_pot)
}

# check those with three values - could be missing or something like that 
cat_vars3 <- names(cat_vars[cat_vars == 3])
pot_cat3 <- pot_cat %>%
	dplyr::filter(variable %in% as.character(cat_vars3))
unique(pot_cat3$label)

# check those with four values also, just in case...
cat_vars4 <- names(cat_vars[cat_vars == 4])
pot_cat4 <- pot_cat %>%
	dplyr::filter(variable %in% as.character(cat_vars4))
unique(pot_cat4$label)
########
### there are lots of variables could be considered binary that are answered with yes/no/DK/other (no idea what other could refer to...)
########

# check those with five values also, just in case...
cat_vars5 <- names(cat_vars[cat_vars == 5])
pot_cat5 <- pot_cat %>%
	dplyr::filter(variable %in% as.character(cat_vars5))
unique(pot_cat5$label)

########
### same issue as above, but add in a missing variable
### Also, issue that some values are "did not have", which == no...
########

### going to remove all but those with three values and go through them individually - cba to do rest...
write.csv(pot_cat3, file = "", quote = F)
### after review it seems there are no variables worth including

# remove binary variables with too few cases

defo_bin_res <- res_bin %>%
	dplyr::select(one_of(as.character(unique(defo_bin$variable))))

few_cases <- apply(defo_bin_res, 2, function(x) {sum(unique(x)[1] == x, na.rm = T) < (nrow(defo_bin_res) / 20)})
few_controls <- apply(defo_bin_res, 2, function(x) {sum(unique(x)[2] == x, na.rm = T) < (nrow(defo_bin_res) / 20)})

cc_var_rm <- unique(c(names(which(few_controls)), names(which(few_cases))))
length(cc_var_rm) # 648
defo_bin_res <- dplyr::select(defo_bin_res, -one_of(cc_var_rm))

# remove binary variables with too much missing
missing <- sapply(defo_bin_res, function(x) {sum(is.na(x))})
names(missing)
vars_rm <- missing[missing > (nrow(defo_bin_res) - 100)]
length(vars_rm) # 0 variables removed due to lack of people

##### can put binary vars with the continuous variables and then can start to document process!
##### still need to go through those which are deleted because they're duplicated
##### ---- can't really do this until Gib sorts out the lack of long labels... - could try python?

summary(nchar(colnames(res3)))

# cc_var_rm <- c(names(which(few_controls)), names(which(few_cases)))
# length(cc_var_rm) # 283
# res3 <- dplyr::select(res3, -one_of(cc_var_rm))

dim(defo_bin_res)

res3 <- cbind(res3, defo_bin_res)

# Rename the headings to remove all the unusable characters for GCTA
colnames(res3) <- gsub("\\%", "percent", colnames(res3))
colnames(res3) <- gsub("[[:punct:]]", "_", colnames(res3))

fin_uniq_vals <- sapply(res3, function(x) {length(unique(x[!is.na(x)]))})
hist(fin_uniq_vals[fin_uniq_vals > 3])
min(fin_uniq_vals[fin_uniq_vals > 3])
which(fin_uniq_vals[fin_uniq_vals > 3] == 10)
poss_cont <- names(fin_uniq_vals[fin_uniq_vals > 3])

phen_list <- colnames(res3)
phen_list <- data.frame(phen = NA, obj = NA, name = NA)
for(i in 1:ncol(res3)) {
	phen_list[i, "phen"] <- colnames(res3)[i]
	if (phen_list[i, "phen"] == "alnqlet") {
		next
	} else if (class(res3[[i]]) == "factor") {
		next
	} else if (phen_list[i, "phen"] == "aln_qlet") {
		next
	}
	phen_list[i, "obj"] <- attr(res3[[i]], "obj")
	phen_list[i, "name"] <- attr(res3[[i]], "name")
}

phen_list <- phen_list %>%
	left_join(fom_diff)
head(phen_list)
unique(phen_list$obj)
matchlist <- c(
			 )
x <- as.character(phen_list$obj) %in% matchlist
fin_phen_list <- rbind(phen_list[x,], phen_list[!x,])
head(fin_phen_list)

# cont_phen_list <- phen_list %>%
# 	dplyr::filter(phen %in% poss_cont)

### read in phenotypes looked at already
alspac_phen <- read_xlsx("")
alspac_phen$age_diff <- as.numeric(alspac_phen$age_diff)

fin_phen_list <- fin_phen_list %>%
	left_join(alspac_phen) %>%
	dplyr::select(obj, name, phen, include, age_diff)

write.table(fin_phen_list, paste0(""), quote = F, col.names = T, row.names = F, sep = "\t")
# write.table(cont_phen_list, paste0("ereml/ALSPAC_data/cont_phen_list_NEW_", timepoints, ".txt"), quote = F, col.names = T, row.names = F, sep = "\t")

fin_phen_list <- read.delim(paste0(""), header = T)

# clinical variables at FOM1 only! 
new_current_clin <- new_current %>% 
	dplyr::filter(path %in% PoI[c(2,4)])

res_fom1 <- res3[, c(1, 2, grep("FOM1", colnames(res3)))]
colnames(res_fom1)
# remove age/time of attendance & fieldworker
res_fom1 <- res_fom1[, -c(3:6)]
nam <- ""
write.table(res_fom1, paste0(""),
			quote = FALSE, col.names = T, row.names = F, sep = "\t")

# Set new password each time
PASSWORD <- ""

zip(paste0(""), 
    files = paste0(""), 
    flags = paste("--password", PASSWORD))

system(paste0("rm ", ""))

# FIN!
