# -------------------------------------------------------
# SVA
# -------------------------------------------------------

# impute function from Matt
impute_matrix <- function(x, FUN = function(x) rowMedians(x, na.rm = T)) {
    idx <- which(is.na(x), arr.ind = T)
    if (length(idx) > 0) {
        v <- FUN(x)
        v[which(is.na(v))] <- FUN(matrix(v, nrow = 1))
        x[idx] <- v[idx[, "row"]]
    }
    return(x)
}

# function to add quotes for weird trait names
addq <- function(x) paste0("`", x, "`")

sv_list <- vector(mode = "list", length = length(phen_nam))
failed <- c()
out_failed <- function(x) {
	sink(file = paste0(out_path, "sv_fails.txt"), append = TRUE, split = TRUE)
	print(x)
	sink()
}

generate_svs <- function(trait, phen_data, meth_data, covariates, nsv, out_path) {
	print(trait)
	phen <- phen_data %>%
		dplyr::select(Sample_Name, one_of(trait, covariates)) %>%
		.[complete.cases(.), ]
	
	mdat <- meth_data[, colnames(meth_data) %in% phen$Sample_Name]
	# full model - with variables of interest 
	fom <- as.formula(paste0("~", addq(trait), " + ",paste(covariates, collapse = " + ")))
	mod <- model.matrix(fom, data = phen)
	# null model
	fom0 <- as.formula(paste0("~", paste(covariates, collapse = "+")))
	mod0 <- model.matrix(fom0, data = phen)

	# Estimate the surrogate variables
	tryCatch({
		svobj <- smartsva.cpp(mdat, mod, mod0, n.sv = nsv)
		svs <- as.data.frame(svobj$sv, stringsAsFactors = F)
		svs$Sample_Name <- phen$Sample_Name
		head(svs)
		colnames(svs)[1:nsv] <- paste0("sv", 1:nsv)

		write.table(svs, file = paste0(out_path, i, ".txt"), sep = "\t", quote = F, col.names = T, row.names = F)

	}, error = function(e) {out_failed(i)})
}
