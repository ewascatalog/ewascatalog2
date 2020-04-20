""" Respond to text queries. 

Unstructured text box queries require further refining. 
The 'execute' function attempts to guess what the user 
is requesting and then provides more specific options/suggestions.

"""

import re
from collections import OrderedDict
from catalog import query, efo

PVALUE_THRESHOLD=5.88e-8


def execute(db, query, max_suggestions):
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
    elif efo_term.matches(db, query):
        ret = efo_term(db, query)
    elif study.matches(db, query):
        ret = study(db, query)
    else:
        ret = trait(db, query)

    ## sort suggested queries by number of CpG site associations
    def byassocs(obj): return obj.assocs()
    suggestions = ret.suggestions()
    for group in suggestions.keys():
        objects = [cached_catalog_object(obj) for obj in suggestions[group]]
        suggestions[group] = sorted(objects, key=byassocs, reverse=True)
        if len(suggestions[group]) > max_suggestions:
            ellipsis = ("... " + str(max_suggestions)
                        + " of " + str(len(suggestions[group]))
                        + " " + group)
            suggestions[group] = suggestions[group][0:max_suggestions-1] + [ellipsis]
        
    suggestions = [suggestions[group] for group in suggestions.keys()]
    suggestions = sum(suggestions, [])
    return suggestions
    
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
    def structured_query_url(self):
        """ URL for submitting a query about this catalog object. """
        return "/?"+self.category+"="+self.value
    def text_query_url(self):
        """ URL for submitting a query about this catalog object. """
        return "/?gene="+self.value
    def title(self):
        """ Catalog object name/value/title. """
        return self.value
    def matches(db, text):
        """ Determine whether text specifies this particular catalog object. """
        return True
    def where_sql(self):
        """ SQL for limiting database query to this particular catalog object. """ 
        return ""
    def assocs(self):
        """ Number of CpG site associations linked to this catalog object. """
        return -1
    def suggestions(self):
        """ List of catalog objects linked to this catalog object (including itself). """
        return []
    def details(self):
        """ Dictionary providing details about this catalog object. """
        details = OrderedDict()
        details['associations'] = self.assocs()
        return details


def assocs_sql(variable, where):
    """ Query template for counting the numbers of CpG site associations. """
    where = where.replace("study_id", "results.study_id")
    variable = variable.replace("study_id", "results.study_id")
    return ("SELECT COUNT(DISTINCT "+variable+") "
            "FROM studies JOIN results "
            "ON studies.study_id=results.study_id "
            "WHERE ( "+where+" ) AND p < "+str(PVALUE_THRESHOLD))

class cpg(catalog_object):
    def __init__(self, db, cpg):
        super().__init__(db, "cpg", cpg.lower().replace(" ", ""))
    def matches(db, text):
        text = text.replace(" ", "")
        return re.match("^cg[0-9]+$", text) or re.match("^ch[0-9]+$", text)
    def where_sql(self):
        return "cpg='"+self.title()+"'"
    def assocs(self):
        ret = query.singleton_response(self.db, assocs_sql("study_id", self.where_sql()))
        return ret.value()
    def suggestions(self):
        """ Suggest querying the CpG site or linked genes. """
        ret = OrderedDict()
        ret['cpg'] = [self]
        links = query.response(self.db, "SELECT gene, study_id FROM results WHERE "+self.where_sql()+" AND p<"+str(PVALUE_THRESHOLD))
        if links.nrow() == 0:
            return ret
        genes = links.col("gene")[0]
        if genes != '-':
            genes = list(set(genes.split(";")))
            ret['genes'] = [gene(self.db, name) for name in genes]
        studies = list(set(links.col("study_id")))
        ret['studies'] = {study(self.db, study_id) for study_id in studies}
        return ret
    def details(self):
        """ Provide CpG site, a linked gene and genic region of the site. """
        details = super().details()
        ret = query.response(self.db, "SELECT chrpos as location, type as region, gene FROM cpgs WHERE " +self.where_sql())
        if ret.nrow() > 0:
            details['location'] = ret.row(0)[0]
            details['gene'] = ret.row(0)[2]
            details['region'] = ret.row(0)[1]
        return details

class loc(catalog_object):
    def __init__(self, db, loc):
        super().__init__(db, "loc", loc.lower().replace("chr", "").replace(" ", ""))
        loc = re.split(":|-",self.title())
        self.chr = loc[0]
        self.pos = loc[1]
    def matches(db, text):
        text = text.replace(" ", "")
        return re.match("^(chr|)[0-9]+:[0-9]+$", text) 
    def where_sql(self):
        return "chrpos='chr"+self.title()+"'"
    def assocs(self):
        ret = query.singleton_response(self.db, assocs_sql("study_id", self.where_sql()))
        return int(ret.value())
    def suggestions(self):
        """ Suggest querying overlapping CpG sites and genes. """ 
        ret = query.response(self.db, "SELECT cpg FROM cpgs WHERE "+self.where_sql())
        if ret.nrow() == 0:
            return {"loc":[self]}
        cpgid = ret.col("cpg")[0]
        return cpg(self.db, cpgid).suggestions()
    def details(self):
        """ Provide location CpG site identifier, linked gene and genic region. """
        details = super().details()
        ret = query.response(self.db, "SELECT cpg, type as region, gene FROM cpgs WHERE " + self.where_sql())
        if ret.nrow() > 0:
            details['identifier'] = ret.row(0)[0]
            details['gene'] = ret.row(0)[1]
            details['region'] = ret.row(0)[2]
        return details

    
class gene(catalog_object):
    def __init__(self, db, gene):
        super().__init__(db, "gene", gene.replace(" ", "").upper())
    def matches(db, text):
        """ Return true if the text matches a gene name in the database. """
        text = text.replace(" ", "").upper()
        if not re.match("[A-Z0-9-]+", text):
            return False
        ret = query.response(db, "SELECT gene FROM genes WHERE gene='"+text+"'")
        return ret.nrow() > 0
    def where_sql(self):
        return "gene='"+self.title()+"'"
    def assocs(self):
        """ Return number of studies with associations involving a CpG site linked to the gene. """
        ret = query.singleton_response(self.db, assocs_sql("cpg,study_id", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest querying the gene itself and CpG sites linked with the gene. """ 
        ret = query.response(self.db, "SELECT cpg FROM cpgs WHERE "+self.where_sql())
        cpgs = ret.col("cpg")
        ret = query.response(self.db, "SELECT study_id FROM results WHERE "+self.where_sql()+" AND p <"+str(PVALUE_THRESHOLD))
        studies = list(set(ret.col("study_id")))
        ret = OrderedDict()
        ret['gene'] = [self]
        if len(cpgs) > 0:
            ret['CpG sites'] = [cpg(self.db, name) for name in cpgs]
        if len(studies) > 0:
            ret['studies'] = [study(self.db, study_id) for study_id in studies]
        return ret
    def details(self):
        """ Provide gene coordinates and number of CpG sites linked to the gene. """
        details = super().details()
        ret = query.response(self.db, "SELECT chr,start,end FROM genes WHERE gene='"+self.title()+"'")
        if ret.nrow() > 0: 
            coords = ret.row(0)
            details['location'] = coords[0] + ":" + str(coords[1]) + "-" + str(coords[2])
        ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT cpg) FROM cpgs WHERE "+self.where_sql())
        details['CpG sites'] = ret.value()
        return details

class region(catalog_object):
    def __init__(self, db, region):
        super().__init__(db, "region", region.replace(" ", "").replace("chr", "").lower())
        region = re.split(':|-',region)
        self.chr = region[0].replace("chr","")
        self.start = region[1]
        self.end = region[2]
    def matches(db, text):
        text = text.replace(" ", "")
        return re.match("^(chr|)[0-9]+:[0-9]+-[0-9]+$", text)
    def where_sql(self):
        return ("chr='"+self.chr+"' "
                "AND pos>="+self.start+" "
                "AND pos<="+self.end)
    def assocs(self):
        """ Return number of studies with associations involving a CpG site inside the region. """
        ret = query.singleton_response(self.db, assocs_sql("cpg,study_id", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest querying the region and genes linked to any CpG site in the region. """
        #ret = query.response(self.db, "SELECT DISTINCT gene from cpgs WHERE " + self.where_sql())
        #genes = ret.col("gene")
        #if "-" in genes:
        #    genes.remove("-")
        #genes = [names.split(";") for names in genes]
        #genes = sum(genes, [])
        #genes = list(set(genes))
        ret = OrderedDict()
        ret["region"] = [self]
        #ret["genes"] = [gene(self.db, name) for name in genes]
        return ret
    def details(self):
        """ Provide the number of CpG sites inside the region. """
        details = super().details()
        ret = query.response(self.db, "SELECT DISTINCT gene FROM cpgs WHERE " + self.where_sql())
        details['genes'] = str(ret.nrow())
        ret = query.singleton_response(self.db, "SELECT COUNT(DISTINCT cpg) FROM cpgs WHERE "+self.where_sql())
        details['CpG sites'] = ret.value()
        return details

class efo_term(catalog_object):
    def __init__(self, db, efo):
        super().__init__(db, "efo", efo.replace(" ", "").upper())
    def matches(db, text):
        text = text.replace(" ", "").upper()
        return re.match("^EFO_[0-9]+$", text)
    def where_sql(self):
        return "efo LIKE '%"+self.title()+"%'"
    def assocs(self):
        """ The number of CpG site associations in EWAS assigned to this EFO term. """
        ret = query.singleton_response(self.db, assocs_sql("cpg,study_id", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest EWAS assigned this EFO term and any EFO term assigned to the same EWAS. """
        ret = query.response(self.db, "SELECT efo, study_id as study FROM studies WHERE " + self.where_sql())
        efo_terms = ret.col("efo")
        efo_terms = [value.replace(" ", "").split(",") for value in efo_terms]
        efo_terms = sum(efo_terms, [])
        efo_terms = set(efo_terms)
        if self.title() in efo_terms:
            efo_terms.remove(self.title())
        studies = ret.col("study")
        studies = set(studies)
        ret = OrderedDict()
        ret['query'] = [self]
        ret['EFO terms'] = [efo_term(self.db, term) for term in efo_terms] 
        ret['studies'] = [study(self.db, study_id) for study_id in studies]
        return ret
    def details(self):
        """ Provide the label for this EFO term. """
        details = super().details()
        label = efo.label(self.title())
        if label != "":
            details['label'] = label
        ret = query.response(self.db, "SELECT DISTINCT pmid FROM studies WHERE " + self.where_sql())
        details['publications'] = ret.nrow()
        return details

class study(catalog_object):
    def __init__(self, db, study):
        super().__init__(db, "study", study.replace(" ", "").lower())
    def matches(db, text):
        text = text.replace(" ", "").lower()
        return re.match("^[0-9]+(_.+|)$", text) 
    def where_sql(self):
        """ Match any EWAS whose PMID or study id matches the input text. """
        return "pmid='"+self.title()+"' OR study_id='"+self.title()+"'"
    def assocs(self):
        """ The number of CpG sites with associations in this EWAS. """
        ret = query.singleton_response(self.db, assocs_sql("cpg", self.where_sql()))
        return int(ret.value())                
    def suggestions(self):
        """ Suggest querying this EWAS or any EFO term linked to this EWAS. """
        ret = query.response(self.db, "SELECT efo, study_id FROM studies WHERE " + self.where_sql())
        efo_terms = ret.col("efo")
        efo_terms = [value.replace(" ", "").split(",") for value in efo_terms]
        efo_terms = sum(efo_terms, [])
        efo_terms = set(efo_terms)
        studies = ret.col("study_id")
        studies = set(studies)
        ret = OrderedDict()
        ret["studies"] = [study(self.db, study_id) for study_id in studies]
        ret["EFO terms"] = [efo_term(self.db, term) for term in efo_terms]
        return ret
    def details(self):
        """ Provide the PMID, authors and number of samples for this EWAS. """
        details = super().details()
        ret = query.response(self.db, "SELECT n, pmid, author, trait, tissue, array FROM studies WHERE " + self.where_sql())
        if ret.nrow() > 0:
            details['author'] = ret.col("author")[0]
            details['PMID'] = ret.col("pmid")[0]
            details['trait'] = ret.col("trait")[0]
            details['tissue'] = ret.col("tissue")[0]
            details['array'] = ret.col("array")[0]
            n = ret.col("n")
            if ret.nrow() > 1:
                n = [int(v) for v in n]
                if min(n) < max(n):
                    n = str(min(n)) + ".." + str(max(n))
                else:
                    n = n[0]
            else:
                n = n[0]
            details['n'] = str(n)
        return details

class trait(catalog_object):
    def __init__(self, db, trait):
        super().__init__(db, "trait", re.sub("[ ]+", " ", trait.lower()))
        self.efo_terms = efo.lookup(self.title()) ## lookup EFO terms for this text
    def matches(db, text):
        return True
    def where_sql(self):
        """ Match any trait containing the supplied text and any associated EFO term. """
        ret = "trait LIKE '%"+self.title()+"%'"
        if len(self.efo_terms) > 0:
            ret = (ret + "OR (efo LIKE '%"+ "%' OR efo LIKE '%".join(self.efo_terms.keys()) + "%') ")
        return ret
    def assocs(self):
        ret = query.singleton_response(self.db, assocs_sql("cpg,study_id", self.where_sql()))
        return int(ret.value())        
    def suggestions(self):
        """ Suggest querying any EWAS with a matching trait or EFO term. """
        ret = query.response(self.db, "SELECT efo, study_id FROM studies WHERE " + self.where_sql())
        efo_terms = ret.col("efo")
        efo_terms = [value.replace(" ", "").split(",") for value in efo_terms]
        efo_terms = sum(efo_terms, [])
        efo_terms = set(efo_terms)
        if "-" in efo_terms:
            efo_terms.remove("-")
        studies = set(ret.col("study_id"))
        ret = OrderedDict()
        ret["EFO terms"] = [efo_term(self.db, term) for term in efo_terms]
        ret["studies"] = [study(self.db, study_id) for study_id in studies]
        return ret
    def details(self):
        """ Provide matching EFO terms. """ 
        details = super().details()
        ret = query.response(self.db, "SELECT distinct pmid FROM studies WHERE " + self.where_sql())
        details['publications'] = ret.nrow()
        if len(self.efo_terms) > 0:
            details['term(s)'] = ", ".join(self.efo_terms.keys())
        return details

class cached_catalog_object(catalog_object):
    """ Catalog object with saved function outputs.

    Accessor functions return results of database queries.  
    This object executes all such functions and saves the outputs
    as object attributes so they can be used by Django to 
    populate web pages. 
    The only exception is the 'suggestions()' function 
    to avoid infinite recursion!
    """ 
    def __init__(self, obj):
        super().__init__(obj.db, obj.category, obj.value)
        self.cached_structured_query_url = obj.structured_query_url()
        self.cached_text_query_url = obj.text_query_url()
        self.cached_details = obj.details()
        self.cached_assocs = obj.assocs()
        self.cached_title = obj.title()
        self.cached_sql = obj.where_sql()
    def structured_query_url(self):
        return self.cached_structured_query_url
    def text_query_url(self):
        return self.cached_text_query_url
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
