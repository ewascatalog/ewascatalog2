""" Respond to structured queries.

Structured queries provide a query 
category (cpg, loc, region, gene, study, trait)
and corresponding value
(CpG identifier, genomic location, genomic region, 
gene name, PMID, EFO identifier).

The response to a query is a table listing 
information for corresponding CpG site associations.
That table is made available to be viewed on a 
web page (via Django) and as a TSV file
for download.
"""

import re
from math import log10, floor
from catalog import query
import time
from django.http import JsonResponse


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
PVALUE_THRESHOLD=1e-4


def execute(db, category, value, max_associations):
    """ Structured query entry point. 

    This function is called in views.py to 
    execute a structured query of the EWAS catalog.
    """
    if category=="cpg":
        ret = response(db, value, cpg_sql(value))
    elif category=="loc":
        ret = response(db, value, loc_sql(value))
    elif category=="region":
        ret = response(db, value, region_sql(value))
    elif category=="gene":
        ret = response(db, value, gene_sql(value))
    elif category=="efo":
        ret = response(db, value, efo_sql(value))
    elif category=="study":
        ret = response(db, value, study_sql(value))
    else:
        ret = ""
    if isinstance(ret, response) and ret.nrow() > max_associations:
        ret.subset(rows=range(max_associations))
    return ret
    

def response_sql(where):
    """ The basic SQL query syntax. 
    
    The query category/value pair determines 
    how the resulting table is restricted. 
    """
    where = where.replace("study_id", "results.study_id")
    return ("SELECT studies.*,results.* "
            "FROM results JOIN studies "
            "ON results.study_id=studies.study_id "
            "WHERE ( "+where+" ) AND p <"+str(PVALUE_THRESHOLD))

def cpg_sql(cpg):
    return response_sql("cpg='"+cpg+"'")

def loc_sql(loc):
    return response_sql("chrpos='"+loc+"'")

def gene_sql(gene):
    return response_sql("gene='"+gene+"'")

def region_sql(region):
    region = re.split(':|-',region)
    chr = region[0]
    start = region[1]
    end = region[2]
    return response_sql("chr='"+chr+"' "
                     "AND pos>="+start+" "
                     "AND pos<="+end)

def efo_sql(terms): 
    return response_sql("efo LIKE '%"+"%' OR efo LIKE '%".join(terms)+"%'")

def study_sql(query):
    return response_sql("pmid='"+query+"' OR study_id='"+query+"'")
           
class response(query.response):
    """ Query response object. 

    Performs the query and provides functions for accessing 
    and manipulating the resulting table. 
    """
    def __init__(self, db, value, sql):
        super().__init__(db, sql)
        self.value = value
        self.sort() ## sort ascending by author, PMID and then p-value.
    def sort(self):
        aux = self.cols.index("author")
        pmx = self.cols.index("pmid")
        pvx = self.cols.index("p")
        self.data.sort(key=lambda x: (x[aux], x[pmx], float(x[pvx])))
    def table(self):
        """ Returns the query table as a tuple of rows with formatted values. """
        cols = HTML_FIELDS
        html_copy = self.copy()
        html_copy.subset(cols=cols)
        formatted_p = [format_pval(pval) for pval in html_copy.col("p")]
        html_copy.set_col("p", formatted_p)
        formatted_beta = [format_beta(beta) for beta in html_copy.col("beta")]
        html_copy.set_col("beta", formatted_beta)
        return tuple(html_copy.data)
    def save(self, path):
        """ Saves the query table to a TSV file and returns the filename. """
        cols = TSV_FIELDS
        tsv_copy = self.copy()
        tsv_copy.subset(cols=cols)
        ts = str(time.time()).replace(".","")
        filename = self.value.replace(" ", "_")+'_'+ts+'.tsv'
        f = open(path+'/'+filename, 'w')
        f.write('\t'.join(tsv_copy.colnames())+'\n')
        for idx in range(tsv_copy.nrow()):
            f.write('\t'.join(str(x) for x in tsv_copy.row(idx))+'\n')
        return filename
    def json(self):
        """ Returns the query table as a JSON response object. """
        return JsonResponse({'results':self.data, 'fields':self.cols})


def round_sig(x, sig=2):
    if x>0:
        return round(x, sig-int(floor(log10(abs(x))))-1)
    else:
        return x 

def format_e(n):
    a = '%E' % n
    return a.split('E')[0].rstrip('0').rstrip('.') + 'E' + a.split('E')[1]

def format_pval(p):
    return str(format_e(round_sig(float(p))))

def format_beta(b):
    try:
        b = float(b)
        if b == 0:
            return 'NA'
        else:
            return str(round_sig(b))
    except (ValueError, TypeError):
        return 'NA'


