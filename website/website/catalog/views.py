from django.shortcuts import render, redirect
import pandas as pd
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
import os, datetime, subprocess, re, shutil
from ratelimit.decorators import ratelimit
from django.conf import settings
from django.core.files.storage import FileSystemStorage
from django.core.mail import EmailMessage

from . import basicquery, advancedquery, database, upload, constants
from .forms import DocumentForm

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TMP_DIR = BASE_DIR+'/catalog/static/tmp/'
UPLOAD_DIR = '/files/ewas-sum-stats/to-add/'



def clear_directory(directory):
    for file in os.listdir(directory):
        curpath = os.path.join(directory+'/'+file)
        file_modified = datetime.datetime.fromtimestamp(os.path.getmtime(curpath))
        if datetime.datetime.now() - file_modified > datetime.timedelta(hours=5):
            os.remove(curpath)

@never_cache
def catalog_home(request):
    clear_directory(TMP_DIR)
    keys = request.GET.keys()
    if len(keys) > 0:
        if "query" in keys:
            return basicquery_response(request)
        else:
            return advancedquery_response(request)
    else:
        return render(request, 'catalog/catalog_home.html', {})

def basicquery_response(request):
    query = request.GET
    text = next(iter(query.values()))
    db = database.default_connection()
    response = basicquery.execute(db, text, constants.MAX_SUGGESTIONS, constants.PVALUE_THRESHOLD)
    if len(response) > 0:
        return render(request, 'catalog/catalog_queries.html',
                      {'query':text.replace(" ", "_"),
                       'query_label':text,
                       'query_list':response})
    else:
        return render(request, 'catalog/catalog_no_results.html',
                      {'query':text})

def advancedquery_response(request):
    query = request.GET
    db = database.default_connection()
    response = advancedquery.execute(db, query, constants.MAX_ASSOCIATIONS, constants.PVALUE_THRESHOLD)            
    if isinstance(response, advancedquery.response):
        filename = response.save(TMP_DIR)
        return render(request, 'catalog/catalog_results.html',
                      {'response':response.table(),
                       'query':response.value.replace(" ", "_"),
                       'query_label':response.value,
                       'filename':filename})
    else:
        return render(request, 'catalog/catalog_no_results.html',
                      {'query':[key+"="+value for key,value in query.items()]})

@never_cache
def catalog_info(request):
    clear_directory(TMP_DIR)
    return render(request, 'catalog/catalog_about.html', {})

@never_cache
def catalog_documents(request):
    clear_directory(TMP_DIR)
    return render(request, 'catalog/catalog_documents.html', {})

@never_cache
def catalog_download(request):
    clear_directory(TMP_DIR)
    return render(request, 'catalog/catalog_download.html', {})

@never_cache
def catalog_upload(request):
    clear_directory(TMP_DIR)
    db = database.default_connection()
    cursor = db.cursor()
    arrays = upload.extract_sql_data("array", cursor)
    tissues = upload.extract_sql_data("tissue", cursor)
    out_ex = (('DNA methylation',))
    if request.method == 'POST':
        form = DocumentForm(request.POST, 
                            request.FILES,
                            array_list=arrays, 
                            tissue_list=tissues, 
                            trait_list=out_ex)
        if form.is_valid():
            rcopy = request.POST.copy()
            name = rcopy.get('name')
            email = rcopy.get('email')
            email_check = upload.check_email(email, request)
            if email_check is not 'valid':
                return email_check

            r_form = request.FILES['results']
            
            r_name = r_form.name
            r_size = r_form.size
            r_limit = 224425040 * 10

            if r_size > r_limit:
                x = "Files uploaded are too big"
                return render(request, 'catalog/catalog_bad_upload_message.html', {
                    'x': x
                })

            if r_name.endswith('.csv'):
                # f_studies = s_form.file
                command = 'Rscript'
                script = 'database/check-ewas-data.r'
                sdata = upload.extract_study_info(rcopy)
                spath = TMP_DIR+name+'-studies.csv'
                sdata.to_csv(spath, index=False)
                f_results = r_form.file
                rdata = pd.read_csv(f_results)
                rpath = TMP_DIR+r_name
                rdata.to_csv(rpath, index=False)

                cmd = [command, script, spath, rpath, UPLOAD_DIR]
                r_out = subprocess.check_output(cmd, universal_newlines=True)
                if r_out == 'Good':
                    # move data into new non-temporary folder
                    studyid = upload.gen_study_id(sdata)
                    upload_path = UPLOAD_DIR+studyid
                    upload.create_dir(upload_path)
                    dt = datetime.datetime.today().__str__().replace(" ", "_")
                    new_spath = upload_path+'/'+dt+'_studies.csv'
                    shutil.move(spath, new_spath)
                    new_rpath = upload_path+'/'+dt+'_results.csv'
                    shutil.move(rpath, new_rpath)
                    # save zenodo data for later
                    zenodo_gen=rcopy.get('zenodo')
                    zen_msg=upload.gen_zenodo_msg(zenodo_gen)
                    upload.save_zenodo_dat(zenodo_gen, rcopy, upload_path)
                    # email
                    report=UPLOAD_DIR+'ewas-catalog-report.html'
                    attachments=[new_spath, report]
                    upload.send_email(name, email, attachments)
                    # remove report and other files it created!
                    os.remove(report)
                    os.remove(UPLOAD_DIR+'ewas-catalog-report.md')
                    os.remove(UPLOAD_DIR+'report-output.txt')
                    return render(request, 'catalog/catalog_upload_message.html', {
                        'email': email, 
                        'zenodo_msg': zen_msg
                    })
                else:
                    return render(request, 'catalog/catalog_bad_upload_message.html', {
                        'x': r_out
                    })
            else: 
                x = "Files aren't csv files"
                return render(request, 'catalog/catalog_bad_upload_message.html', {
                    'x': x
                })
            return render(request, 'catalog/catalog_upload_message.html')
    else:
        form = DocumentForm(array_list=arrays, tissue_list=tissues, trait_list=out_ex)
    return render(request, 'catalog/catalog_upload.html', {
        'form': form
    })


# @never_cache
# def catalog_upload(request):
#     clear_directory(TMP_DIR)
#     if request.method == 'POST':
#         form = DocumentForm(request.POST, request.FILES)
#         if form.is_valid():
#             name = request.POST.get('name')
#             email = request.POST.get('email')
#             email_check = upload.check_email(email, request)
#             if email_check is not 'valid':
#                 return email_check

#             s_form = request.FILES['studies']
#             r_form = request.FILES['results']
            
#             s_name = s_form.name
#             s_size = s_form.size
#             s_limit = 10 * 1024 * 1024

#             r_name = r_form.name
#             r_size = r_form.size
#             r_limit = 224425040 * 10

#             if r_size < r_limit and s_size < s_limit:
#                 if r_name.endswith('.csv') and s_name.endswith('.csv'):
#                     f_studies = s_form.file
#                     command = 'Rscript'
#                     script = 'database/check-ewas-data.r'
#                     sdata = pd.read_csv(f_studies)
#                     spath = TMP_DIR+s_name
#                     sdata.to_csv(spath, index=False)
#                     f_results = r_form.file
#                     rdata = pd.read_csv(f_results)
#                     rpath = TMP_DIR+r_name
#                     rdata.to_csv(rpath, index=False)

#                     cmd = [command, script, spath, rpath, TMP_DIR]
#                     r_out = subprocess.check_output(cmd, universal_newlines=True)
#                     if r_out == 'Good':
#                         # move data into new non-temporary folder
#                         studyid = gen_study_id(sdata)
#                         upload_path = UPLOAD_DIR+studyid
#                         upload.create_dir(upload_path)
#                         dt = datetime.datetime.today().__str__().replace(" ", "_")
#                         new_spath = upload_path+'/'+dt+'_studies.csv'
#                         shutil.move(spath, new_spath)
#                         new_rpath = upload_path+'/'+dt+'_results.csv'
#                         shutil.move(rpath, new_rpath)
#                         # email
#                         report=TMP_DIR+'ewas-catalog-report.html'
#                         attachments=[new_spath, report]
#                         upload.send_email(name, email, attachments)
#                         return render(request, 'catalog/catalog_upload_message.html', {
#                             'email': email
#                         })
#                     else:
#                         return render(request, 'catalog/catalog_bad_upload_message.html', {
#                             'x': r_out
#                         })
#                     return render(request, 'catalog/catalog_upload_message.html')
#                 else:
#                     x = "Files aren't csv files"
#                     return render(request, 'catalog/catalog_bad_upload_message.html', {
#                         'x': x
#                     })
#             else:
#                 x = "Files uploaded are too big"
#                 return render(request, 'catalog/catalog_bad_upload_message.html', {
#                     'x': x
#                 })
#     else:
#         form = DocumentForm()
#     return render(request, 'catalog/catalog_upload.html', {
#         'form': form
#     })

@ratelimit(key='ip', rate='1000/h', block=True)
def catalog_api(request):
    db = database.default_connection()
    query = request.GET 
    ret = advancedquery.execute(db, query, constants.MAX_ASSOCIATIONS*100, constants.PVALUE_THRESHOLD)
    if isinstance(ret, advancedquery.response):
        return ret.json()
    else:
        return JsonResponse({})
