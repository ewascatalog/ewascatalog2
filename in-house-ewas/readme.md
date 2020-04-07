# Scripts for in-house EWAS for the catalog

These scripts are for extracting and cleaning phenotype data, cleaning DNA methylation data and then running EWAS in ARIES and for some phenotype data in GEO. The phenotype data for GEO was already extracted by Dr. Paul Yousefi using [geograbi](https://github.com/yousefi138/geograbi).

To use these scripts a text file or shell script must be created in this directory called "filepaths.sh" with all the filepaths and files needed. A template can be found at filepaths_template.sh

## ALSPAC

* ALSPAC data are extracted using __alspac_data_extraction.R__, which saves the data in the RDSF in an encrypted file.
* PCs are generated using __aries_pca.sh__
* The aries DNA methylation data is cleaned in __clean_aries_meth.R__
* Outliers are removed from phenotypes and covariates are combined with phenotype data in __combine_traits_and_covariates.R__
* 

## GEO

* 

## Other

* The ewas for either cohort can be run using __ewas_script.R__, which uses the package [ewaff](https://github.com/perishky/ewaff) for the analyses.
* Finally the data are formatted for the catalog using __format_for_catalog.R__

## Issues

* Directories will need to be updated or code changed when more ARIES timepoints are added (essentially each timepoint will have to be treated as a different cohort with the current code!)
* There are still some outdated things in the ewas script that only work for ARIES data --> Simple fix
* The scripts for GEO haven't been tested yet! 