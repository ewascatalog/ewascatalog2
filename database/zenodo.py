# script to upload a file to zenodo sandbox via api
# seperate sandbox- and real-zenodo accounts and ACCESS_TOKENs each need to be created

# to adapt this script to real-zenodo (from sandbox implementation):
    # update urls to zenodo.org from sandbox.zenodo.org
    # update SANDBOX_TOKEN to a ACCESS_TOKEN from real-zenodo

import sys, json, requests
import pandas as pd

studyid = sys.argv[1]
file_dir = sys.argv[2]
access_token = sys.argv[3]
data_dir = file_dir+'/ewas-sum-stats/published/'+studyid

zfile=data_dir+'/zenodo.csv'
try:
    zdata = pd.read_csv(zfile)
except FileNotFoundError:
    print("Can't find the file "+zfile)
    sys.exit()

# specify ACCESS_TOKEN
  # this needs to be generated for each sanbox/real account
ACCESS_TOKEN = access_token

# create empty upload
headers = {"Content-Type": "application/json"}
r = requests.post('https://zenodo.org/api/deposit/depositions', params={'access_token': ACCESS_TOKEN}, json={}, headers=headers)

r.status_code
r.json()

# Get the deposition id from the previous response
# Upload the file to be deposited to Zenodo
deposition_id = r.json()['id']
# data = {'name': 'crime1.csv'}
# files = {'file': open('/Users/paulyousefi/crime1.csv', 'rb')}
data = {'name': 'results.txt'}
files = {'file': open(data_dir+'/results.txt')}
r = requests.post('https://zenodo.org/api/deposit/depositions/%s/files' % deposition_id, params={'access_token': ACCESS_TOKEN}, data=data, files=files)

r.status_code
r.json()

# specify and attach the metadata for the upload
# data = {'metadata': {'title': 'My first upload', 'upload_type': 'poster', 'description': 'This is my first upload', 'creators': [{'name': 'Doe, John', 'affiliation': 'Zenodo'}]}}
# sdata = pd.read_table(data_dir+'/studies.txt')
# sdata = pd.read_csv("../test_files/studies_450k_test.csv")

title = zdata.loc[0, 'title']
authors = zdata.loc[0, 'authors']
desc = zdata.loc[0, 'desc']

desc = desc + '\n\n' + 'Upload of this dataset was completed by The EWAS Catalog team. The data can be queried along with hundreds of other EWAS at ewascatalog.org. To upload your EWAS summary statistics and have a zenodo DOI generated for you go to ewascatalog.org/upload'

# au = sdata.loc[0, 'Author']
# pmid = sdata.loc[0, 'PMID']
# trait = sdata.loc[0, 'Trait']
# title = au + ' et al. EWAS of ' + trait + '. PMID = ' + str(pmid)
# desc = 'Upload of this dataset was completed by The EWAS Catalog team. The data can be queried along with hundreds of other EWAS at ewascatalog.org. To upload your EWAS summary statistics and have a zenodo DOI generated for you go to ewascatalog.org/upload'

data = {'metadata': 
				   {'title': title, 
				    'upload_type': 'dataset', 
				    'description': desc, 
				    'creators': [{'name': authors}]}}

r = requests.put('https://zenodo.org/api/deposit/depositions/%s' % deposition_id, params={'access_token': ACCESS_TOKEN}, data=json.dumps(data), headers=headers)

r.status_code
r.json()

# publish 
r = requests.post('https://zenodo.org/api/deposit/depositions/%s/actions/publish' % deposition_id, params={'access_token': ACCESS_TOKEN} )

status_code = r.status_code
if status_code != 202:
	raise ValueError("Status code was" + str(status_code) + " and it should be 202. Check zenodo")
else:
	print("Status code is 202 so it seems")
# should be: 202
