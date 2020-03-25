# Scripts for in-house EWAS for the catalog

## ALSPAC

* ALSPAC data are extracted using __alspac_data_extraction.R__, which saves the data in the RDSF in an encrypted file.
* Distributions of data are checked using __check_phenos.R__
* The data are then combined with the sample file, covariates and slightly tidied in __tidy_alspac_ewas_data.R__. It's now ready for the EWAS.

## GEO

* 

All the ewas are conducted on bluecrystal. For alspac data that will need to be extracted using __alspac_data_extraction.R__ where it will be put into the RDSF. From there it can be accessed and moved on bluecrystal ready for the EWAS. Move the data using __rdsf_move.sh__. 