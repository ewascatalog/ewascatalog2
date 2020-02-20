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

$(WEBSITE_DIR)/website/manage.py: website/website/website/*.py website/website/catalog/*.py
	#bash website/install-dependencies.sh
	mkdir -p $(WEBSITE_DIR)
	rm -rf $(WEBSITE_DIR)/website
	cp -rv website/website $(WEBSITE_DIR)
	cp settings.env $(WEBSITE_DIR)/website
	cp $(FILE_DIR)/catalog-download/ewascatalog.txt.gz $(WEBSITE_DIR)/website/catalog/static/docs

website: $(WEBSITE_DIR)/website/manage.py

startwebsite: $(WEBSITE_DIR)/website/manage.py
	python3 $< runserver

## to do: command to start webserver 

## to do: command to get website running in a docker container

## to do: command to update database
