from django.shortcuts import render, redirect
from pandas import read_csv
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
import os, datetime
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
            sdata = read_csv(f_studies)
            sdata.to_csv('temp/temp_studies.csv')
            f_results = request.FILES['results'].file
            rdata = read_csv(f_results)
            rdata.to_csv('temp/temp_results.csv')
            return redirect('catalog_upload')
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
