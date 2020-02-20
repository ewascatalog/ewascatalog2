from django.shortcuts import render, redirect
from django.http import HttpResponseBadRequest, HttpResponse, JsonResponse
from django.views.decorators.cache import never_cache, cache_control
import MySQLdb, re, os, glob, csv, time, datetime, sched, requests, string, tabix
import MySQLdb.cursors
from ratelimit.decorators import ratelimit
from django.conf import settings
import gzip
import re

from catalog import catalogquery

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TMP_DIR = BASE_DIR+'/catalog/static/tmp/'
HTML_FIELDS = ["author","pmid","outcome","exposure","analysis","n",
               "cpg","chrpos","gene","beta","p"]
TSV_FIELDS = ["author","consortium","pmid","date","trait","efo",
              "analysis","source","outcome","exposure","covariates",
              "outcome_unit","exposure_unit","array","tissue",
              "further_details","n","n_studies","categories",
              "age","n_males","n_females","n_eur","n_eas","n_sas",
              "n_afr","n_amr","n_oth",
              "cpg","chrpos","chr","pos","gene","type",
              "beta","se","p","details","study_id"]

def default_db_connection():
    dbhost = settings.DATABASES['default']['HOST']
    dbuser = settings.DATABASES['default']['USER']
    dbpassword = settings.DATABASES['default']['PASSWORD']
    dbname = settings.DATABASES['default']['NAME']
    db = MySQLdb.connect(host=dbhost,user=dbuser,password=dbpassword,db=dbname)
    return(db)

def clear_directory(directory):
    for file in os.listdir(directory):
        curpath = os.path.join(directory+'/'+file)
        file_modified = datetime.datetime.fromtimestamp(os.path.getmtime(curpath))
        if datetime.datetime.now() - file_modified > datetime.timedelta(hours=5):
            os.remove(curpath)

def retrieve_efo_terms(query):
    q=re.sub('[^a-zA-Z\d\s]', '', query).replace(" ", "+")
    punc = re.compile('[%s]' % re.escape(string.punctuation))
    efo = str(requests.get('http://www.ebi.ac.uk/spot/zooma/v2/api/services/annotate?propertyValue='+q).json())
    efo = punc.sub(' ', efo)
    efo_term = list(filter(lambda x: re.search('^EFO_',x), efo.replace("EFO ", "EFO_").split()))
    efo_terms1 = list(sorted(set(efo_term), key=efo_term.index))
    efo = str(requests.get('http://www.ebi.ac.uk/spot/zooma/v2/api/services/annotate?propertyValue='+q+'&filter=required:[gwas]').json())
    efo = punc.sub(' ', efo)
    efo_term = list(filter(lambda x: re.search('^EFO_',x), efo.replace("EFO ", "EFO_").split()))
    efo_terms2 = list(sorted(set(efo_term), key=efo_term.index))
    efo_term = efo_terms1 + efo_terms2
    efo_terms = list(sorted(set(efo_term), key=efo_term.index))
    efo_terms = [x for x in efo_terms if x!="EFO_UKB"]
    return efo_terms

      
@never_cache
def catalog_home(request):
    clear_directory(TMP_DIR)
    query = request.GET.get("query", None)
    if query:
        query = query.strip()
        db = default_db_connection()
        ret = ""
        if re.match("^cg[0-9]+", query):
            ret = catalogquery.cpg(db, query)
        elif re.match("^ch\.[0-9]+\.[0-9]+", query):
            ret = catalogquery.cpg(db, query)
        elif re.match("^chr[0-9]+:[0-9]+", query):
            ret = catalogquery.loc(db, query)
        elif re.match("[0-9]+:[0-9]+-[0-9]+", query):
            ret = catalogquery.region(db, query, query)
        elif re.match(r'(\s|^|$)'+"[A-Z0-9-]+"+r'(\s|^|$)', query):
            coords = catalogquery.genecoords(db, query)
            if coords:
                ret = catalogquery.region(db, query, coords)
        if not ret:
            terms = retrieve_efo_terms(query)
            if terms:
                ret = catalogquery.efo(db, query, terms)
            else:
                ret = 'catalog/catalog_no_results.html'
        if isinstance(ret, catalogquery.response):
            ret.sort()
            filename = ret.save(TMP_DIR, TSV_FIELDS)
            data = ret.format(HTML_FIELDS)
            return render(request, 'catalog/catalog_results.html',
                          {'result':tuple(data),
                           'query':query.replace(" ", "_"),
                           'query_label':query,
                           'filename':filename})
        else:
            return render(request, ret, {'query': query})        
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

@ratelimit(key='ip', rate='1000/h', block=True)
def catalog_api(request):
    db = default_db_connection()
    ret = ""
    if "cpg" in request.GET:
        query = request.GET.get("cpg")
        if re.match("^cg[0-9]+", query):
            ret = catalogquery.cpg(db, query)
        elif re.match("^ch\.[0-9]+\.[0-9]+", query):
            ret = catalogquery.cpg(db, query)
    elif "region" in request.GET:
        query = request.GET.get("region")
        ret = catalogquery.region(db,query,query)
    elif "gene" in request.GET:
        query = request.GET.get("gene")
        coords = catalogquery.genecoords(db, query)
        if coords:
            ret = catalogquery.region(db, query, coords)
    elif "trait" in request.GET:
        query = request.GET.get("trait")
        terms = retrieve_efo_terms(query)
        if terms:
            ret = catalogquery.efo(db, query, terms)
    if isinstance(ret, catalogquery.response):
        ret.sort()
        return JsonResponse({'results':ret.data, 'fields':ret.cols})
    else:
        return JsonResponse({})
