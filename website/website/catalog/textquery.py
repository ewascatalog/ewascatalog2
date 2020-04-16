""" Respond to text queries. 

Unstructured text box queries require further refining. 
The 'execute' function attempts to guess what the user 
is requesting and then provides more specific options/suggestions.
"""

import re
from catalog import query, efo

def execute(db, query):
    """ Text query entry point. 

    This function is called in views.py to 
    respond to a text query from the EWAS catalog website.
    It attempts to guess what the user is requesting ('matches' functions)
    and then provides more specific options/suggestions.
    """ 
    ret = ""
    if cpg.matches(db, query):
        ret = cpg(db, query)
    elif loc.matches(db, query):
        ret = loc(db, query)
    elif region.matches(db, query):
        ret = region(db, query)
    elif gene.matches(db, query):
        ret = gene(db, query)
    elif efo.matches(db, query):
        ret = efo(db, query)
    elif study.matches(db, query):
        ret = study(db, query)
    else
        ret = trait(db, query)

    ## ret.suggestions() provides suggested queries
    ## to send back to the user. 
    ## Each suggestion is accompanied by information 
    ## derived from multiple database queries. 
    ## Each suggestion is used to construct a 
    ## 'cached_catalog_object' which runs each of these 
    ## queries and saves the results.
    return [cached_catalog_object(obj) for obj in ret.suggestions()]

class catalog_object:
    """ Abstract EWAS catalog object
    
    An EWAS catalog object consists of a category 
    (CpG, genomic location, gene, genomic region, 
    study, EFO or trait)
    and corresponding value submitted by the user
    (CpG identifier, genomic coordinates, gene name, 
    PMID, EFO identifier, or trait name).
    
    Attributes:
    db: Database connection object.
    category: Object category (see above).
    value: Object value (see above).
    """ 
    def __init__(self, db, category, value):
        self.db = db
        self.category = category
        self.value = value
    def url(self):
        """ URL for submitting a query about this catalog object. """
        return "/?"+self.category+"="+self.value
    def title(self):
        """ Catalog object name/value/title. """
        return value
    def matches(db, text):
        """ Determine whether text specifies this particular catalog object. """
        return True
    def where_sql(self):
        """ SQL for limiting database query to this particular catalog object. """ 
        return ""
    def assocs(self):
        """ Number of CpG site associations linked to this catalog object. """
        return 0
    def suggestions(self):
        """ List of catalog objects linked to this catalog object (including itself). """
        return []
    def details(self):
        """ Dictionary providing details about this catalog object. """
        details = OrderedDict()
        details['associations'] = self.assocs()
        return details

class cached_catalog_object(catalog_object):
    """ Catalog object with saved function outputs.

    Accessor functions return results of database queries.  
    This object executes all such functions and saves the outputs
    so database queries do not need to be rerun later.
    The only exception is the 'suggestions()' function 
    to avoid infinite recursion!
    """ 
    def __init__(self, obj):
        super().__init__(obj.db, obj.category, obj.value)
        cached_url = obj.url()
        cached_details = obj.details()
        cached_assocs = obj.assocs()
        cached_title = obj.title()
        cached_sql = obj.where_sql()
    def url(self):
        return self.cached_url
    def title(self):
        return self.cached_title
    def matches(db, text):
        return True
    def where_sql(self):
        return self.cached_sql
    def assocs(self):
        return self.cached_assocs
    def suggestions(self):
        return []
    def details(self):
        return self.cached_details

def assocs_sql(variable, where):
    """ Query template for counting the numbers of CpG site associations. """ 
    return ("SELECT COUNT(DISTINCT "+variable+") AS associations"
            "FROM studies JOIN results "
            "ON studies.study_id=results.study_id "
            "WHERE ("+where+") AND p < 1e-7")

class cpg(catalog_object):
    def __init__(self, db, cpg):
        super().__init__(self, db, "cpg", cpg)
    def matches(db, text):
        return re.match("^cg[0-9]+$", text) or re.match("^ch[0-9]+$", text)
    def where_sql(self):
        return "cpg=='"+self.value+"'"
    def assocs(self):
        ret = query.singleton_response(self.db, assocs_sql("study_id", self.where_sql()))
        return ret.value()
    def suggestions(self):
        """ Suggest querying the CpG site or linked genes. """
        ret = [self]
        genes = query.singleton_response(self.db, "SELECT gene FROM cpgs WHERE "+self.where_sql())
        if genes.nrow() == 0:
            return ret
        genes = genes.value()
        if genes == '-':
            return ret
        genes = list(set(genes.split(";")))
        return ret + [gene(self.db, name) for name in genes]
    def details(self):
        """ Provide CpG site, a linked gene and genic region of the site. """
        details = super().details()
        ret = query.response(db, "SELECT chrpos as location, type as region, gene FROM cpgs WHERE ", self.where_sql())
        if ret.nrow() > 0:
            details['location'] = ret.row(0)[0]
            details['gene'] = ret.row(0)[1]
            details['region'] = ret.row(0)[2]
        return details

class loc(catalog_object):
    def __init__(self, db, loc):
        super().__init__(self, db, "loc", loc)
        loc = re.split(":|-",loc)
        self.chr = loc[0]
        self.pos = loc[1]
    def matches(db, text):
        return re.match("^chr[0-9]+:[0-9]+$", text)
    def where_sql(self):
        return "chrpos='"+self.value+"'"
    def assocs(self):
        ret = query.singleton_response(self.db, assocs_sql("study_id", self.where_sql()))
        return int(ret.value())
    def suggestions(self):
        """ Suggest querying overlapping CpG sites and genes. """ 
        ret = query.response(self.db, "SELECT cpg FROM cpgs WHERE "+self.where_sql())
        cpgs = ret.col("cpg")
        ret = query.response(self.db, 
                    "SELECT DISTINCT gene FROM genes WHERE "
                    "chr='"+self.chr+"' AND start<="+self.pos+" AND end>="+self.pos)
        genes = ret.col("gene")
        return [self] + [cpg(self.db, name) for name in cpgs] + [gene(self.db, name) for name in genes]
    def details(self):
        """ Provide location CpG site identifier, linked gene and genic region. """
        details = super().details()
        ret = query.response(db, "SELECT cpg, type as region, gene FROM cpgs WHERE ", self.where_sql())
        if ret.nrow() > 0:
            details['identifier'] = ret.row(0)[0]
            details['gene'] = ret.row(0)[1]
            details['region'] = ret.row(0)[2]
        return details

class gene(catalog_object):
    def __init__(self, db, gene):
        super().__init__(self, db, "gene", gene)
    def matches(db, text):
        """ Return true if the text matches a gene name in the database. """
        if not re.match(r'(\s|^|$)'+"[A-Z0-9-]+"+r'(\s|^|$)', text):
            return False
        ret = query.response(db, "SELECT gene FROM genes WHERE gene='"+text+"'")
        return ret.nrow() > 0
    def where_sql(self):
        return "gene='"+self.value+"'"
    def assocs(self):
        """ Return number of studies with associations involving a CpG site linked to the gene. """
        ret = query.singleton_response(self.db, assocs_sql("study_id", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest querying the gene itself and CpG sites linked with the gene. """ 
        ret = query.response(self.db, "SELECT cpg FROM cpgs WHERE "+self.where_sql())
        cpgs = ret.col("cpg")
        return [self] + [cpg(self.db, name) for name in cpgs]
    def details(self):
        """ Provide gene coordinates and number of CpG sites linked to the gene. """
        details = super().details()
        ret = query.response(db, "SELECT chr,start,end FROM genes WHERE gene='"+text+"'")
        if ret.nrow() > 0: 
            coords = ret.row(0)
            details['location'] = coords[0] + ":" + coords[1] + "-" + coords[2]
        ret = query.singleton_response("SELECT COUNT(DISTINCT cpg) FROM cpgs WHERE "+self.where_sql())
        details['CpG sites'] = ret.value()
        return details

class region(catalog_object):
    def __init__(self, db, region):
        super().__init__(self, db, "region", region)
        region = re.split(':|-',self.value)
        self.chr = region[0]
        self.start = region[1]
        self.end = region[2]
    def matches(db, text):
        return re.match("^chr[0-9]+:[0-9]+-[0-9]+$", text)
    def where_sql(self):
        return ("chr='"+self.chr+"' "
                "AND pos>="+self.start+" "
                "AND pos<="+self.end)
    def assocs(self):
        """ Return number of studies with associations involving a CpG site inside the region. """
        ret = query.singleton_response(self.db, assocs_sql("study_id", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest querying the region and genes linked to any CpG site in the region. """
        ret = query.response(self.db, "SELECT DISTINCT gene FROM cpgs WHERE "+self.where_sql())
        genes = ret.col("gene")
        return [self] + [gene(self.db, name) for name in genes]
    def details(self):
        """ Provide the number of CpG sites inside the region. """
        details = super().details()
        ret = query.singleton_response("SELECT COUNT(DISTINCT cpg) FROM cpgs WHERE "+self.where_sql())
        details['CpG sites'] = ret.value()
        return details

class efo(catalog_object):
    def __init__(self, db, efo):
        super().__init__(self, db, "efo", efo)
    def matches(db, text):
        return re.match("^EFO_[0-9]+$", text)
    def where_sql(self):
        return "efo LIKE '%"+self.value+"%'"
    def assocs(self):
        """ The number of CpG site associations in EWAS assigned to this EFO term. """
        ret = query.singleton_response(self.db, assocs_sql("cpg", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest EWAS assigned this EFO term and any EFO term assigned to the same EWAS. """
        ret = query.response(self.db, "SELECT efo, study_id as study FROM studies WHERE " + self.where_sql())
        efo_terms = ret.col("efo")
        efo_terms = [value.replace(" ", "").split(",") for value in efo_terms]
        efo_terms = sum(efo_terms, [])
        efo_terms = set(efo_terms)
        efo_terms.remove(self.value)
        studies = ret.col("study")
        studies = set(studies)
        return ([self] 
                + [efo(self.db, term) for term in efo_terms] 
                + [study(study_id) for study_id in studies])
    def details(self):
        """ Provide the label for this EFO term. """
        details = super().details()
        label = efo.label(self.value)
        if label != "":
            details['label'] = label
        return details

class study(catalog_object):
    def __init__(self, db, study):
        super().__init__(self, db, "study", study)
    def matches(db, text):
        return re.match("^[0-9]+$", text)
    def where_sql(self):
        """ Match any EWAS whose PMID or study id matches the input text. """
        return "pmid='"+self.value+"' OR study_id='"+self.value+"'"
    def assocs(self):
        """ The number of CpG sites with associations in this EWAS. """
        ret = query.singleton_response(self.db, assocs_sql("cpg", self.where_sql()))
        return int(ret.value())                
    def suggestions(self):
        """ Suggest querying this EWAS or any EFO term linked to this EWAS. """
        ret = query.response(self.db, "SELECT efo FROM studies WHERE " + self.where_sql())
        efo_terms = ret.col("efo")
        efo_terms = [value.replace(" ", "").split(",") for value in efo_terms]
        efo_terms = sum(efo_terms, [])
        efo_terms = set(efo_terms)
        studies = ret.col("study")
        studies = set(studies)
        return ([study(study_id) for study_id in studies]
                + [efo(self.db, term) for term in efo_terms])
    def details(self):
        """ Provide the PMID, authors and number of samples for this EWAS. """
        details = super().details()
        ret = query.response(self.db, "SELECT n, pmid, author FROM studies WHERE " + self.where_sql())
        if ret.nrow(ret) > 0:
            details['author'] = ret.col("author")[0]
            details['PMID'] = ret.col("pmid")[0]
            n = ret.col("n")
            if ret.nrow() > 1:
                n = [int(v) for v in n]
                if min(n) < max(n):
                    n = min(n) + ".." + max(n)
                else:
                    n = n[0]
            details['n'] = n
        return details

class trait(catalog_object):
    def __init__(self, db, trait):
        super().__init__(self, db, "trait", trait)
        self.efo_terms = efo.lookup(self.value) ## lookup EFO terms for this text
    def matches(db, text):
        return True
    def where_sql(self):
        """ Match any trait containing the supplied text and any associated EFO term. """
        ret = "trait LIKE '%"+trait+"%'"
        if len(self.efo_terms) > 0:
            ret = ret + "OR (efo LIKE '%"+ "%' OR efo LIKE '%".join(self.efo_terms.keys()) + "%') ")
        return ret
    def assocs(self):
        ret = query.singleton_response(self.db, assocs_sql("cpg", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest querying any EWAS with a matching trait or EFO term. """
        ret = query.response(self.db, "SELECT efo, study_id as study FROM studies WHERE " + self.where_sql())
        efo_terms = ret.col("efo")
        efo_terms = [value.replace(" ", "").split(",") for value in efo_terms]
        efo_terms = sum(efo_terms, [])
        efo_terms = set(efo_terms)
        studies = ret.col("study")
        studies = set(studies)
        return ([self] 
                + [efo(self.db, term) for term in efo_terms] 
                + [study(study_id) for study_id in studies])
    def details(self):
        """ Provide matching EFO terms. """ 
        details = super().details()
        ret = self.value
        if (len(self.efo_terms) > 0:
            details['term(s)'] = ", ".join(self.efo_terms.keys())
        return details
