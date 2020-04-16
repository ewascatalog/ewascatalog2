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
from query import response

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

def execute(db, category, value):
    """ Structured query entry point. 

    This function is called in views.py to 
    execute a structured query of the EWAS catalog.
    """
    if category=="cpg":
        return response(db, value, cpg_sql(value))
    elif category=="loc":
        return response(db, value, loc_sql(value))
    elif category=="region":
        return response(db, value, region_sql(value))
    elif category=="gene":
        return response(db, value, gene_sql(value))
    elif category=="trait":
        return response(db, value, trait_sql(value))
    elif category=="study":
        return response(db, value, study_sql(value))
    else:
        return ""

def response_sql(where):
    """ The basic SQL query syntax. 
    
    The query category/value pair determines 
    how the resulting table is restricted. 
    """
    return ("SELECT studies.*,results.* "
            "FROM results JOIN studies "
            "ON results.study_id=studies.study_id "
            "WHERE ("+where+") AND p < 1e-4")

def cpg_sql(cpg):
    return response_sql("cpg='"+cpg+"'")

def loc_sql(loc):
    return response_sql("chrpos='"+loc+"'")

def gene_sql(cpg):
    return response_sql("gene='"+gene+"'")

def region_sql(region):
    region = re.split(':|-',query)
    chr = region[0]
    start = region[1]
    end = region[2]
    return response_sql("chr='"+chr+"' "
                     "AND pos>="+start+" "
                     "AND pos<="+end)

def trait_sql(terms): 
    return response_sql("efo LIKE '%"+"%' or efo LIKE '%".join(terms)+"%'")

def study_sql(pmid):
    return response_sql("pmid='"+pmid+"'")
           
class response(query.response):
    """ Query response object. 

    Performs the query and provides functions for accessing 
    and manipulating the resulting table. 
    """
    def __init__(self, db, value, sql):
        query.__init__(self, db, sql)
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
        subset = self.subset(None, cols)
        formatted_p = [format_pval(pval) for pval in subset.col("p")]
        subset.set_col("p", formatted_p)
        formatted_beta = [format_beta(beta) for beta in subset.col("beta")]
        subset.set_col("beta", formatted_beta)
        return tuple(subset.data)
    def save(self, path):
        """ Saves the query table to a TSV file and returns the filename. """
        cols = TSV_FIELDS
        subset = self.subset(None, cols)
        ts = str(time.time()).replace(".","")
        filename = self.value.replace(" ", "_")+'_'+ts+'.tsv'
        f = open(path+'/'+filename, 'w')
        f.write('\t'.join(subset.colnames())+'\n')
        for idx in range(subset.nrow()):
            f.write('\t'.join(str(x) for x in subset.row(idx))+'\n')
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


