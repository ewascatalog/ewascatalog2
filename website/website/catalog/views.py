from django.shortcuts import render, redirect
import pandas as pd
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
import os, datetime, subprocess, re
from ratelimit.decorators import ratelimit
from django.conf import settings
from django.core.files.storage import FileSystemStorage

from . import textquery, structuredquery, database
from .models import Doc
from .forms import DocumentForm

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TMP_DIR = BASE_DIR+'/catalog/static/tmp/'

MAX_SUGGESTIONS=10
MAX_ASSOCIATIONS=1000


def clear_directory(directory):
    for file in os.listdir(directory):
        curpath = os.path.join(directory+'/'+file)
        file_modified = datetime.datetime.fromtimestamp(os.path.getmtime(curpath))
        if datetime.datetime.now() - file_modified > datetime.timedelta(hours=5):
            os.remove(curpath)

@never_cache
def catalog_home(request):
    clear_directory(TMP_DIR)
    keys = list(request.GET.keys())
    if len(keys) > 0:
        db = database.default_connection()
        key = keys[0]
        query = list(request.GET.values())[0]
        query = query.strip()
        if key == "query":
            query_list = textquery.execute(db, query, MAX_SUGGESTIONS)
            if len(query_list) > 0:
                return render(request, 'catalog/catalog_queries.html',
                              {'query':query.replace(" ", "_"),
                               'query_label':query,
                               'query_list':query_list})
            else:
                return render(request, 'catalog/catalog_no_results.html',
                              {'query':query})
        else:
            ret = structuredquery.execute(db, key, query, MAX_ASSOCIATIONS)            
            if isinstance(ret, structuredquery.response):
                filename = ret.save(TMP_DIR)
                return render(request, 'catalog/catalog_results.html',
                              {'result':ret.table(),
                               'query':query.replace(" ", "_"),
                               'query_label':query,
                               'filename':filename})
            else:
                return render(request, 'catalog/catalog_no_results.html',
                              {'query':query})
    else:
        return render(request, 'catalog/catalog_home.html', {})


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

def check_email(email):
    regex = '^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$'
    if(re.search(regex, email)):
        return 'valid'
    else:
        return 'invalid'

@never_cache
def catalog_upload(request):
    clear_directory(TMP_DIR)
    if request.method == 'POST':
        form = DocumentForm(request.POST, request.FILES)
        if form.is_valid():
            email = request.POST.get('email')
            email_check = check_email(email)
            if email_check == 'valid':
                s_form = request.FILES['studies']
                r_form = request.FILES['results']
                
                s_name = s_form.name
                s_size = s_form.size
                s_limit = 10 * 1024 * 1024

                r_name = r_form.name
                r_size = r_form.size
                r_limit = 224425040 * 10

                if r_size < r_limit and s_size < s_limit:
                    if r_name.endswith('.csv') and s_name.endswith('.csv'):
                        f_studies = s_form.file
                        command = 'Rscript'
                        script = 'database/check-ewas-data.r'
                        sdata = pd.read_csv(f_studies)
                        spath = TMP_DIR+'temp_studies.csv'
                        sdata.to_csv(spath, index=False)
                        f_results = r_form.file
                        rdata = pd.read_csv(f_results)
                        rpath = TMP_DIR+'temp_results.csv'
                        rdata.to_csv(rpath, index=False)

                        cmd = [command, script, spath, rpath]
                        x = subprocess.check_output(cmd, universal_newlines=True)
                        if x == 'Good':
                            return render(request, 'catalog/catalog_upload_message.html')
                        else:
                            return render(request, 'catalog/catalog_bad_upload_message.html', {
                                'x': x
                            })
                        return render(request, 'catalog/catalog_upload_message.html')
                    else:
                        x = "Files aren't csv files"
                        return render(request, 'catalog/catalog_bad_upload_message.html', {
                            'x': x
                        })
                else:
                    x = "Files uploaded are too big"
                    return render(request, 'catalog/catalog_bad_upload_message.html', {
                        'x': x
                    })
            else:
                x = "The email address "+email+" is a bad email address."
                return render(request, 'catalog/catalog_bad_upload_message.html', {
                    'x': x
                })            
    else:
        form = DocumentForm()
    return render(request, 'catalog/catalog_upload.html', {
        'form': form
    })

@ratelimit(key='ip', rate='1000/h', block=True)
def catalog_api(request):
    db = database.default_connection()
    category = request.GET.keys()[0]
    query = request.GET.values()[0]
    ret = structuredquery.execute(db, category, query)
    if isinstance(ret, structuredquery.response):
        return ret.json()
    else:
        return JsonResponse({})
