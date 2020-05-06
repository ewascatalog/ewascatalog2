from django.shortcuts import render, redirect
import pandas as pd
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
import os, datetime, subprocess
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

@never_cache
def catalog_upload(request):
    clear_directory(TMP_DIR)
    if request.method == 'POST':
        form = DocumentForm(request.POST, request.FILES)
        if form.is_valid():
            f_studies = request.FILES['studies'].file
            command = 'Rscript'
            script = 'database/check-ewas-data.r'
            sdata = pd.read_csv(f_studies)
            spath = TMP_DIR+'temp_studies.csv'
            sdata.to_csv(spath, index=False)
            f_results = request.FILES['results'].file
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

            # Rscript f_studies ## what this script should do:
            # 1. Read in the data (test with end)
            # 2. Output a message saying the data has been read (test first then put at end)
            # 3. Check column names
            # 4. Check data length
            # 5. Check no missing "essential" values
            # 6. Check data types
            # 7. Check data matches (e.g. number of CpGs doesn't go over number of mentioned array)
            # 8. 
            return render(request, 'catalog/catalog_upload_message.html')
    else:
        form = DocumentForm()
    return render(request, 'catalog/catalog_upload.html', {
        'form': form
    })

# @never_cache
# def catalog_upload(request):
#     clear_directory(TMP_DIR)
#     if request.method == 'POST':
#         form = DocumentForm(request.POST, request.FILES)
#         if form.is_valid():
#             f_studies = request.FILES['studies'].file
#             sdata = read_csv(f_studies)
#             sdata.to_csv('temp/temp_studies.csv')
#             f_results = request.FILES['results'].file
#             rdata = read_csv(f_results)
#             rdata.to_csv('temp/temp_results.csv')
#             return render(request, 'catalog/catalog_upload_message.html')
#     else:
#         form = DocumentForm()
#     return render(request, 'catalog/catalog_upload.html', {
#         'form': form
#     })

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
