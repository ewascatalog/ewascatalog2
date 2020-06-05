import os

"""
Maximum number of suggestions returned by a 'basic' query
"""
MAX_SUGGESTIONS=100

"""
Maximum number of associations returned by a query
"""
MAX_ASSOCIATIONS=10000

"""
P-value threshold for counting and returning associations
"""
PVALUE_THRESHOLD=1e-4

"""
Directories
""" 
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TMP_DIR = BASE_DIR+'/catalog/static/tmp/'
UPLOAD_DIR = '/files/ewas-sum-stats/to-add/'