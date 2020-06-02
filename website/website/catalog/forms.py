from django import forms
from django.conf import settings
from . import textquery, structuredquery, database, upload
	
class ListTextWidget(forms.TextInput):
	""" Custom widget to allow users to choose
	from previous entries

	This widget is used in the DocumentForm form below
	"""
	def __init__(self, data_list, name, *args, **kwargs):
		super(ListTextWidget, self).__init__(*args, **kwargs)
		self._name = name
		self._list = data_list
		self.attrs.update({'list':'list__%s' % self._name})

	def render(self, name, value, attrs=None, renderer=None):
		text_html = super(ListTextWidget, self).render(name, value, attrs=attrs)
		data_list = '<datalist id="list__%s">' % self._name
		for item in self._list:
			data_list += '<option value="%s">' % item
		data_list += '</datalist>'

		return (text_html + data_list)

class DocumentForm(forms.Form):
	# study information
	name = forms.CharField(max_length=50)
	email = forms.EmailField()
	author = forms.CharField(max_length=50, label="First Author (Surname Initials)")
	consortium = forms.CharField(required=False, max_length=50)
	pmid = forms.CharField(max_length=20, label="PubMed ID (or DOI)")
	publication_date = forms.DateField(required=False, label="Publication Date (DD/MM/YY)")
	trait = forms.CharField(max_length=100, label="Trait")
	efo = forms.CharField(required=False, max_length=50, label="EFO Term")
	analysis = forms.CharField(required=False, max_length=100, label="Analysis (e.g. Discovery or Discovery and replication)")
	source = forms.CharField(required=False, max_length=50, label="Source (e.g. Table 1, Table S1)")
	# analysis information
	outcome = forms.CharField(max_length=200, label="Outcome")
	exposure = forms.CharField(max_length=200, label="Exposure")
	covariates = forms.CharField(required=False, max_length=300, label="Covariates (eg. Age, sex and smoking)")
	outcome_unit = forms.CharField(required=False, max_length=50, label="Outcome Units")
	exposure_unit = forms.CharField(required=False, max_length=50, label="Exposure Units")
	array = forms.CharField(max_length=50, label="Methylation Array")
	tissue = forms.CharField(max_length=100, label="Tissue")
	further_details = forms.CharField(required=False, max_length=200, label="Further Details")
	# participant info
	n = forms.CharField(max_length=20, label="Total Number of Participants")
	n_studies = forms.CharField(max_length=20, label="Total Number of Cohorts")
	categories = forms.CharField(max_length=200, required=False, label="Categories (eg. 200 smokers, 200 non-smokers)")
	age = forms.CharField(max_length=5, required=False, label="Mean age (in years)")
	n_males = forms.CharField(max_length=20, required=False, label="Total Number of Males")
	n_females = forms.CharField(max_length=20, required=False, label="Total Number of Females")
	n_eur = forms.CharField(max_length=20, required=False, label="Total Number of Europeans")
	n_eas = forms.CharField(max_length=20, required=False, label="Total Number of East Asians")
	n_sas = forms.CharField(max_length=20, required=False, label="Total Number of South Asians")
	n_afr = forms.CharField(max_length=20, required=False, label="Total Number of Africans")
	n_amr = forms.CharField(max_length=20, required=False, label="Total Number of Admixed Americans (eg. Mexican)")
	n_oth = forms.CharField(max_length=20, required=False, label="Total Number of Other Ancestry")
	# zenodo info
	zenodo = forms.ChoiceField(choices=[('Yes', 'Yes'), ('No', 'No')], label="Generate zenodo DOI?")
	zenodo_title = forms.CharField(required = False, max_length=200, label="Title of Manuscript")
	zenodo_desc = forms.CharField(required = False, max_length=5000, widget=forms.Textarea(), label="Description for Zenodo (e.g. manuscript abstract)")
	zenodo_authors = forms.CharField(required = False, max_length=200, label="All Authors")
	# results upload
	results = forms.FileField(label = "Results File")
	# def __init__ for multiple choice lists
	def __init__(self, *args, **kwargs):
		_array_list = kwargs.pop('array_list', None)
		_tissue_list = kwargs.pop('tissue_list', None)
		_trait_list = kwargs.pop('trait_list', None)
		super(DocumentForm, self).__init__(*args, **kwargs)
		self.fields['array'].widget = ListTextWidget(data_list=_array_list, name='array-list')
		self.fields['tissue'].widget = ListTextWidget(data_list=_tissue_list, name='tissue-list')
		self.fields['outcome'].widget = ListTextWidget(data_list=_trait_list, name='outcome-list')
		self.fields['exposure'].widget = ListTextWidget(data_list=_trait_list, name='exposure-list')

