# script to upload a file to zenodo sandbox via api
# seperate sandbox- and real-zenodo accounts and ACCESS_TOKENs each need to be created

# to adapt this script to real-zenodo (from sandbox implementation):
    # update urls to zenodo.org from sandbox.zenodo.org
    # update SANDBOX_TOKEN to a ACCESS_TOKEN from real-zenodo

import sys, json, requests
import pandas as pd

def examine_user_input(add_zenodo):
	if add_zenodo not in ["y", "n"]:
		raise ValueError("Please enter 'y' or 'n'")
	elif add_zenodo == "n":
		print("You have chosen against producing a zenodo doi for the data")
		sys.exit()
	elif add_zenodo == "y":
		add_zenodo2 = input("Are you sure you want to create a zenodo doi? [y/n] ")
		if add_zenodo2 not in ["y", "n"]:
			raise ValueError("Please enter 'y' or 'n'")
		elif add_zenodo2 == "n":
			print("You have chosen against producing a zenodo doi for the data")
			sys.exit()
		elif add_zenodo2 == "y":
 			print("Continuing with making a zenodo doi")

studyid = sys.argv[1]
file_dir = sys.argv[2]
data_dir = file_dir+'/ewas-sum-stats/published/'+studyid

add_zenodo = input("Create zenodo doi for data with study ID: "+studyid+"? [y/n] ")

examine_user_input(add_zenodo)

# specify ACCESS_TOKEN
  # this needs to be generated for each sanbox/real account
SANDBOX_TOKEN = '...'

# create empty upload
headers = {"Content-Type": "application/json"}
r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions', params={'access_token': SANDBOX_TOKEN}, json={}, headers=headers)

r.status_code
r.json()

# Get the deposition id from the previous response
# Upload the file to be deposited to Zenodo
deposition_id = r.json()['id']
# data = {'name': 'crime1.csv'}
# files = {'file': open('/Users/paulyousefi/crime1.csv', 'rb')}
data = {'name': 'results.txt'}
files = {'file': open(data_dir+'/results.txt')}
r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions/%s/files' % deposition_id, params={'access_token': SANDBOX_TOKEN}, data=data, files=files)

r.status_code
r.json()

# specify and attach the metadata for the upload
# data = {'metadata': {'title': 'My first upload', 'upload_type': 'poster', 'description': 'This is my first upload', 'creators': [{'name': 'Doe, John', 'affiliation': 'Zenodo'}]}}
# sdata = pd.read_table(data_dir+'/studies.txt')
sdata = pd.read_csv("../test_files/studies_450k_test.csv")

au = sdata.loc[0, 'Author']
pmid = sdata.loc[0, 'PMID']
trait = sdata.loc[0, 'Trait']
title = au + ' et al. EWAS of ' + trait + '. PMID = ' + str(pmid)
desc = 'Upload of this dataset was completed by The EWAS Catalog team. The data can be queried along with hundreds of other EWAS at ewascatalog.org. To upload your EWAS summary statistics and have a zenodo DOI generated for you go to ewascatalog.org/upload'

data = {'metadata': 
				   {'title': title, 
				    'upload_type': 'dataset', 
				    'description': desc, 
				    'creators': [{'name': au}]}}

[{'name': 'Doe, John', 'affiliation': 'Zenodo'}]
r = requests.put('https://sandbox.zenodo.org/api/deposit/depositions/%s' % deposition_id, params={'access_token': SANDBOX_TOKEN}, data=json.dumps(data), headers=headers)

r.status_code
r.json()

# publish 
r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions/%s/actions/publish' % deposition_id, params={'access_token': SANDBOX_TOKEN} )

r.status_code
# should be: 202
