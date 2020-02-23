load.library <- function(pkg, bioc=F, ...) {
  installed <- installed.packages()[,"Package"]
  is.git <- grepl("github", pkg)
  if (!is.git && !pkg %in% installed) {
    if (bioc) {
      if (!requireNamespace("BiocManager", quietly = TRUE))
        install.packages("BiocManager")
      BiocManager::install(pkg, ...)
    } else {
      install.packages(pkg, dependencies=TRUE, repos="https://www.stats.bris.ac.uk/R/", ...)
    }
  } else {
    if (!"devtools" %in% installed)
      load.library("devtools")
    devtools::install_git(pkg, ...)
    pkg <- basename(pkg)
  }
  library(pkg, character.only=TRUE)
}

