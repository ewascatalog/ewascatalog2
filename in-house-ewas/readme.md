# Scripts for in-house EWAS for the catalog

These scripts are for extracting and cleaning phenotype data, cleaning DNA methylation data and then running EWAS in ARIES and for some phenotype data in GEO. The phenotype data for GEO was already extracted by Dr. Paul Yousefi using [geograbi](https://github.com/yousefi138/geograbi).

To use these scripts a text file or shell script must be created in this directory with all the filepaths and files needed. An template can be found at filepaths_template.sh

## ALSPAC

* ALSPAC data are extracted using __alspac_data_extraction.R__, which saves the data in the RDSF in an encrypted file.
* PCs are generated using __aries_pca.sh__
* Outliers are removed from phenotypes and covariates are combined with phenotype data in __combine_traits_and_covariates.R__
* The aries DNA methylation data is cleaned in __filter_aries_cpgs.R__
* 

## GEO

* 

All the ewas are conducted on bluecrystal. For alspac data that will need to be extracted using __alspac_data_extraction.R__ where it will be put into the RDSF. From there it can be accessed and moved on bluecrystal ready for the EWAS. Move the data using __rdsf_move.sh__. 