# script to upload a file to zenodo sandbox via api
# seperate sandbox- and real-zenodo accounts and ACCESS_TOKENs each need to be created

# to adapt this script to real-zenodo (from sandbox implementation):
    # update urls to zenodo.org from sandbox.zenodo.org
    # update SANDBOX_TOKEN to a ACCESS_TOKEN from real-zenodo

import requests
import json

# specify ACCESS_TOKEN
#   this needs to be generated for each sanbox/real account
SANDBOX_TOKEN = '...'

# create empty upload
headers = {"Content-Type": "application/json"}
r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions', params={'access_token': SANDBOX_TOKEN}, json={}, headers=headers)

r.status_code
r.json()

# Get the deposition id from the previous response
# Upload the file to be deposited to Zenodo
deposition_id = r.json()['id']
data = {'name': 'crime1.csv'}
files = {'file': open('/Users/paulyousefi/crime1.csv', 'rb')}
r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions/%s/files' % deposition_id, params={'access_token': SANDBOX_TOKEN}, data=data, files=files)

r.status_code
r.json()

# specify and attach the metadata for the upload
data = {'metadata': {'title': 'My first upload', 'upload_type': 'poster', 'description': 'This is my first upload', 'creators': [{'name': 'Doe, John', 'affiliation': 'Zenodo'}]}}

r = requests.put('https://sandbox.zenodo.org/api/deposit/depositions/%s' % deposition_id, params={'access_token': SANDBOX_TOKEN}, data=json.dumps(data), headers=headers)

r.status_code
r.json()

# publish 
r = requests.post('https://sandbox.zenodo.org/api/deposit/depositions/%s/actions/publish' % deposition_id, params={'access_token': SANDBOX_TOKEN} )

r.status_code
# should be: 202
