## Makefile requires settings for variables FILE_DIR, WEBSITE_DIR and DB. 
## These can be found in the following file:
##   /projects/MRC-IEU/research/projects/ieu1/wp2/004/working/scripts/ewascatalog2/settings.env
SETTINGS=../settings.env
include $(SETTINGS)

$(FILE_DIR)/cpg_annotation.txt:
	Rscript --vanilla annotations/create-cpg-annotation.r $@

$(FILE_DIR)/gene_annotation.txt:
	Rscript --vanilla annotations/create-gene-annotation.r $@

cpgs: $(FILE_DIR)/cpg_annotation.txt
	bash database/create-cpg-annotation.sh $(DB) $(FILE_DIR)

genes: $(FILE_DIR)/gene_annotation.txt
	bash database/create-gene-annotation.sh $(DB) $(FILE_DIR)

database: $(FILE_DIR)/published-ewas/*.txt $(FILE_DIR)/aries-ewas/*.txt
	bash database/create-database.sh $(DB) $(FILE_DIR) $(SETTINGS)

dependencies:
	bash website/install-dependencies.sh

$(WEBSITE_DIR)/manage.py: website/website/website/*.py website/website/catalog/*.py
	## prepare to copy
	mkdir -p $(WEBSITE_DIR)
	## delete old versions 
	rm -rf $(WEBSITE_DIR)/*
	## copy the website files
	cp -rv website/website/* $(WEBSITE_DIR)
	## copy over settings.env
	cp $(SETTINGS) $(WEBSITE_DIR)
	## create directory for temporary files
	mkdir -p $(WEBSITE_DIR)/catalog/static/tmp
	## copy ewas catalog download file
	mkdir -p $(WEBSITE_DIR)/catalog/static/docs
	cp $(FILE_DIR)/catalog-download/ewascatalog.txt.gz \
	   $(WEBSITE_DIR)/catalog/static/docs
	## set file permissions for apache2 web server
	chmod -R o-rwx ${WEBSITE_DIR}
	chgrp -R www-data ${WEBSITE_DIR}
	chmod -R g-w ${WEBSITE_DIR}
	chmod -R g+w ${WEBSITE_DIR}/catalog/static/tmp

website: $(WEBSITE_DIR)/manage.py

startwebsite: $(WEBSITE_DIR)/manage.py
	python3 $< runserver

## to do: command to start webserver 

## to do: command to get website running in a docker container

## to do: command to update database
