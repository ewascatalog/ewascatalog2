""" Deal with file uploads.

Users can upload their data and it should be checked
and an email sent to them detailing what they've sent
"""

import os, re
import pandas as pd
from django.core.mail import EmailMessage
from django.shortcuts import render

def check_email(email, request):
	""" Simple email check.

	This function is called in views.py to
	check the email entered is valid with regards 
	to structure. 
	"""
	regex = '^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$'
	if(re.search(regex, email)):
		return 'valid'
	else:
		x = "The email address "+email+" is a bad email address."
		return render(request, 'catalog/catalog_bad_upload_message.html', {
			'x': x
		})            


def extract_study_info(rcopy):
	""" Extracting study information from POST data.

	This function is called in views.py to
	extract the user input POST data from the upload 
	page. 
	"""
	covs = rcopy.getlist('covariates')
	other_covs = rcopy.get('other_covariates')
	covs.append(other_covs)
	study_dat = {'Author': [rcopy.get('author')],
				 'Consortium': [rcopy.get('consortium')],
				 'PMID': [rcopy.get('pmid')],
				 'Date': [rcopy.get('publication_date')],
				 'Trait': [rcopy.get('trait')],
				 'EFO': [rcopy.get('efo')],
				 'Analysis': [rcopy.get('analysis')],
				 'Source': [rcopy.get('source')],
				 'Outcome': [rcopy.get('outcome')],
				 'Exposure': [rcopy.get('exposure')],
				 'Covariates': [', '.join(covs)],
				 'Outcome_Units': [rcopy.get('outcome_unit')],
				 'Exposure_Units': [rcopy.get('exposure_unit')],
				 'Methylation_Array': [rcopy.get('array')],
				 'Tissue': [rcopy.get('tissue')],
				 'Further_Details': [rcopy.get('further_details')],
				 'N': [rcopy.get('n')],
				 'N_Cohorts': [rcopy.get('n_studies')],
				 # 'Categories': [rcopy.get('categories')],
				 'Age': [rcopy.get('age')],
				 'Sex': [rcopy.get('sex')],
				 # 'N_Males': [rcopy.get('n_males')],
				 # 'N_Females': [rcopy.get('n_females')],
				 'Ethnicity': [', '.join(rcopy.getlist('ethnicity'))]
				 # 'N_EUR': [rcopy.get('n_eur')],
				 # 'N_EAS': [rcopy.get('n_eas')],
				 # 'N_SAS': [rcopy.get('n_sas')],
				 # 'N_AFR': [rcopy.get('n_afr')],
				 # 'N_AMR': [rcopy.get('n_amr')],
				 # 'N_OTH': [rcopy.get('n_oth')]
				}
	df = pd.DataFrame(study_dat)
	return df

def isNaN(num):
    return num != num

def gen_study_id(study_dat):
	""" Generating a Study ID from the study data.

	This function is called in views.py to
	generate the study ID 
	"""    
	df = study_dat
	auth_nam = df.iloc[0]['Author'].replace(" ", "-")
	trait_nam = df.iloc[0]['Trait'].replace(" ", "_").lower()
	if isNaN(df.iloc[0]['PMID']):
	    StudyID = auth_nam+"_"+trait_nam
	else:
	    StudyID = str(df.iloc[0]['PMID'])+"_"+auth_nam+"_"+trait_nam
	if isNaN(df.iloc[0]['Analysis']):
		analysis_nam = df.iloc[0]['Analysis'].replace(" ", "_").lower()
		StudyID = StudyID+'_'+analysis_nam

	return StudyID

def extract_sql_data(var, cursor):
	""" Extracting variables from database.

	This function is used in views.py to extract 
	data from the ewascatalog database and this 
	can be used to populate multiple choice options
	on the upload webpage 
	"""    
	sql = "SELECT DISTINCT "+var+" FROM studies"
	cursor.execute(sql)
	results = cursor.fetchall()
	return results

def gen_zenodo_msg(zenodo):
	""" Generating zenodo message.

	This function is used in views.py. 
	It takes a Yes/No answer as input by the user 
	on the upload webpage and gives a message to them
	letting them know whether a doi will be generated
	"""    	
	if zenodo == 'Yes':
	    msg = 'You indicated you wanted a zenodo doi so we will generate this for you with the information you provided.'
	else:
	    msg = 'You indicated you did not want a zenodo doi.'
	return msg

def save_zenodo_dat(zenodo, rcopy, upload_path):
	""" Saving zenodo data.

	This function is used in views.py to save
	the zenodo data if it is provided
	"""    		
	if zenodo == 'No':
	    return None
	else:
		zen_dat = {'desc': [rcopy.get('zenodo_desc')], 
					'title': [rcopy.get('zenodo_title')],
					'authors': [rcopy.get('zenodo_authors')]
					}
		df = pd.DataFrame(zen_dat)
		df.to_csv(upload_path+'/zenodo.csv', index=False)


def create_dir(new_dir):
    if not os.path.exists(new_dir):
        os.mkdir(new_dir)

def send_email(name, useremail, attachments):
	""" Send emails to users.

    This function is called in views.py to
    send an email to users who upload data 
    to the catalog.
    """
	email_start = 'Dear '+name+',\n\n'
	email_body = 'Thank you for uploading your results to the EWAS Catalog. Please find attached an initial report on the data you uploaded. We will conduct more checks and if the data looks good we will email you with a zenodo doi and to let you know the data is in the catalog.\n\n'
	email_end = 'Kind regards,\nThe EWAS Catalog team'
	email_full_body = email_start+email_body+email_end
	email_msg = EmailMessage(
	    subject = ['Automated EWAS Catalog Upload message'],
	    body = email_full_body,
	    from_email = 'ewascatalog@outlook.com',
	    to = [useremail],
	    bcc = ['thomas.battram@bristol.ac.uk']
	)    
	for file in attachments:
	    email_msg.attach_file(file)        
	email_msg.send()
