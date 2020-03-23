import time
import gzip
import re
from math import log10, floor
from decimal import Decimal


## Class for EWAS catalog query results
## consist mainly of a table:
## cols = names of columns
## data = rows of the table
class response:
    def __init__(self, db, query, sql):
        cur = db.cursor()      
        cur.execute(sql)
        self.sql = sql
        self.cols = [x[0] for x in cur.description]
        self.data = list(cur.fetchall())
        self.query = query
    def sql(self, query):
        return ""
    def sort(self):
        aux = self.cols.index("author")
        pmx = self.cols.index("pmid")
        pvx = self.cols.index("p")
        self.data.sort(key=lambda x: (x[aux], x[pmx], float(x[pvx])))
    def subset_by_cols(self, cols):
        cx = [self.cols.index(name) for name in cols]
        return [[x[i] for i in cx] for x in self.data]
    def format(self, cols):
        data = self.subset_by_cols(cols)
        px = cols.index("p")
        bx = cols.index("beta")
        for x in data:
            x[px] = format_pval(x[px])
            x[bx] = format_beta(x[bx])
        return data
    def save(self, path, cols):
        data = self.subset_by_cols(cols)
        ts = str(time.time()).replace(".","")
        filename = self.query.replace(" ", "_")+'_'+ts+'.tsv'
        f = open(path+'/'+filename, 'w')
        f.write('\t'.join(cols)+'\n')
        for row in data:
            f.write('\t'.join(str(x) for x in row)+'\n')
        return filename

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


class cpg(response):
    def __init__(self, db, cpg):
        response.__init__(self, db, cpg, self.sql(cpg))
    def sql(self, query):
        cpg = query
        return ("SELECT studies.*,results.* "
                "FROM results JOIN studies "
                "ON results.study_id=studies.study_id "
                "WHERE cpg='"+cpg+"' AND p < 1")
    
class loc(response):
    def __init__(self, db, loc):    
        response.__init__(self, db, loc, self.sql(loc))
    def sql(self, query):
        loc = query
        return ("SELECT studies.*,results.* "
                "FROM results JOIN studies "
                "ON results.study_id=studies.study_id "
                "WHERE chrpos='"+loc+"' AND p < 1")
    
class region(response):
    def __init__(self, db, query, region):
        response.__init__(self, db, query, self.sql(region))
    def sql(self, query):
        region = re.split(':|-',query)
        chr = region[0]
        start = region[1]
        end = region[2]
        return ("SELECT studies.*,results.* "
                "FROM results JOIN studies "
                "ON results.study_id=studies.study_id "
                "WHERE chr='"+chr+"' "
                "AND pos>="+start+" "
                "AND pos<="+end+" "
                "AND p < 1e-4")
 
class efo(response):
    def __init__(self, db, query, terms):
        response.__init__(self, db, query, self.sql(terms))
    def sql(self, query):
        terms = query
        return("SELECT studies.*,results.* "
               "FROM studies JOIN results "
               "ON studies.study_id=results.study_id "
               "WHERE (efo LIKE '%"+"%' or efo LIKE '%".join(terms)+"%') "
               "AND p < 1e-7")


def genecoords(db, symbol):
    sql = ("SELECT gene,ensembl_id,chr,start,end "
           "FROM genes WHERE gene='"+symbol+"'")
    cur = db.cursor()      
    if cur.execute(sql) > 0:        
        info = list(cur.fetchall()[0])
        return info[2] + ":" + str(info[3]) + "-" + str(info[4])
    else:
        return ""
