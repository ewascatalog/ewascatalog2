""" Deal with file uploads.

Users can upload their data and it should be checked
and an email sent to them detailing what they've sent
"""

import os, re
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
