from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.cache import never_cache
import os, datetime
from ratelimit.decorators import ratelimit

from . import textquery, structuredquery, database

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TMP_DIR = BASE_DIR+'/catalog/static/tmp/'


def clear_directory(directory):
    for file in os.listdir(directory):
        curpath = os.path.join(directory+'/'+file)
        file_modified = datetime.datetime.fromtimestamp(os.path.getmtime(curpath))
        if datetime.datetime.now() - file_modified > datetime.timedelta(hours=5):
            os.remove(curpath)

@never_cache
def catalog_home(request):
    clear_directory(TMP_DIR)
    query = request.GET.get("query", None)
    if query:
        query = query.strip()
        db = database.default_connection()
        ret = textquery.execute(db, query)
        if len(ret) > 0:
            return render(request, 'catalog/catalog_queries.html',
                          {'query':query.replace(" ", "_"),
                           'query_label':query,
                           'query_list':ret})
        else:
            return render(request, 'catalog/catalog_no_results.html')
    else:
        return render(request, 'catalog/catalog_home.html', {})


@never_cache
def catalog_queries(request):
    db = database.default_connection()
    category = request.GET.keys()[0]
    query = request.GET.values()[0]
    ret = structuredquery.execute(db, category, query)
    if isinstance(ret, structuredquery.response):
        filename = ret.save(TMP_DIR)
        return render(request, 'catalog/catalog_results.html',
                      {'result':ret.table(),
                       'query':query.replace(" ", "_"),
                       'query_label':query,
                       'filename':filename})
    else:
        return render(request, ret, {'query': query})        

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
