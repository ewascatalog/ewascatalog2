from django import forms
from django.conf import settings
	
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

COVARIATE_CHOICES = [
	('Age', 'Age'),
	('Sex', 'Sex'), 
	('Smoking', 'Smoking'),
	('Cell composition (reference based)', 'Cell composition (reference based)'),
	('Cell composition (reference free)', 'Cell composition (reference free)'),
	('Batch effects (PCA)', 'Batch effects (PCA)'), 
	('Batch effects (SVA)', 'Batch effects (SVA)'), 
	('Batch effects (other)', 'Batch effects (other)'),
	('Ancestry (genomic PCs)', 'Ancestry (genomic PCs)'), 
	('Ancestry (other)', 'Ancestry (other)'),
	('Body mass index', 'Body mass index'), 
	('Gestational age', 'Gestational age'), 
	('Socio-economic position', 'Socio-economic position'), 
	('Education', 'Education'), 
	('Birthweight', 'Birthweight')
]

AGE_CHOICES = [
	('Infants', 'Infants'),
	('Children', 'Children'),
	('Adults', 'Adults'),
	('Geriatrics', 'Geriatrics')
]

SEX_CHOICES = [
	('Males', 'Males'),
	('Females', 'Females'),
	('Both', 'Both')
]

ETHNICITY_CHOICES = [
	('European', 'European'),
	('East Asian', 'East Asian'), 
	('South Asian', 'South Asian'),
	('African', 'African'),
	('Admixed', 'Admixed'),
	('Other', 'Other'), 
	('Unclear', 'Unclear')
]

class DocumentForm(forms.Form):
	# study information
	name = forms.CharField(max_length=50, label = "Name*")
	email = forms.EmailField(label = "Email*")
	author = forms.CharField(max_length=50, label="First Author (Surname Initials)*")
	consortium = forms.CharField(required=False, max_length=50)
	pmid = forms.CharField(required=False, max_length=20, label="PubMed ID (or DOI)")
	publication_date = forms.DateField(required=False, label="Publication Date (DD/MM/YY)")
	trait = forms.CharField(max_length=100, label="Trait*")
	efo = forms.CharField(required=False, max_length=50, label="EFO Term")
	analysis = forms.CharField(required=False, max_length=100, label="Analysis (e.g. Discovery or Discovery and replication)")
	source = forms.CharField(required=False, max_length=50, label="Source (e.g. Table 1, Table S1)")
	## analysis information
	outcome = forms.CharField(max_length=200, label="Outcome*")
	exposure = forms.CharField(max_length=200, label="Exposure*")
	covariates = forms.MultipleChoiceField(required=False, label="Covariates (select all that apply)",
								 widget=forms.CheckboxSelectMultiple, choices=COVARIATE_CHOICES)
	other_covariates = forms.CharField(required=False, max_length = 300, label="Other Covariates (Please separate each with a comma, e.g. a covariate, another covariate)")
	outcome_unit = forms.CharField(required=False, max_length=50, label="Outcome Units (e.g. Beta values)")
	exposure_unit = forms.CharField(required=False, max_length=50, label="Exposure Units")
	array = forms.CharField(max_length=50, label="Methylation Array*")
	tissue = forms.CharField(max_length=100, label="Tissue* (start typing to see some options)")
	further_details = forms.CharField(required=False, max_length=200, label="Extra important details about the analysis (e.g. analysis of twins)")
	## participant info
	n = forms.CharField(max_length=20, label="Total Number of Participants*")
	n_studies = forms.CharField(max_length=20, label="Total Number of Cohorts*")
	# categories = forms.CharField(max_length=200, required=False, label="Categories (eg. 200 smokers, 200 non-smokers)")
	age = forms.ChoiceField(label="Age group* (choose the most prominent age group in your study)", 
							widget=forms.RadioSelect, choices=AGE_CHOICES)
	sex = forms.ChoiceField(label='Sex*', widget=forms.RadioSelect, choices=SEX_CHOICES)
	# n_males = forms.CharField(max_length=20, required=False, label="Total Number of Males")
	# n_females = forms.CharField(max_length=20, required=False, label="Total Number of Females")
	ethnicity = forms.MultipleChoiceField(label='Ethnicity* (select all that apply)', 
										  widget=forms.CheckboxSelectMultiple, choices=ETHNICITY_CHOICES)
	# n_eur = forms.CharField(max_length=20, required=False, label="Total Number of Europeans")
	# n_eas = forms.CharField(max_length=20, required=False, label="Total Number of East Asians")
	# n_sas = forms.CharField(max_length=20, required=False, label="Total Number of South Asians")
	# n_afr = forms.CharField(max_length=20, required=False, label="Total Number of Africans")
	# n_amr = forms.CharField(max_length=20, required=False, label="Total Number of Admixed Americans (eg. Mexican)")
	# n_oth = forms.CharField(max_length=20, required=False, label="Total Number of Other Ancestry")
	## zenodo info
	zenodo = forms.ChoiceField(choices=[('Yes', 'Yes'), ('No', 'No')], widget=forms.RadioSelect, label="Generate zenodo DOI?*")
	zenodo_title = forms.CharField(required = False, max_length=200, label="Title of Manuscript")
	zenodo_desc = forms.CharField(required = False, max_length=5000, widget=forms.Textarea(), label="Description for Zenodo (e.g. manuscript abstract)")
	zenodo_authors = forms.CharField(required = False, max_length=200, label="All Authors")
	## results upload
	results = forms.FileField(label = "Results File*")
	## def __init__ for multiple choice lists
	def __init__(self, *args, **kwargs):
		_array_list = kwargs.pop('array_list', None)
		_tissue_list = kwargs.pop('tissue_list', None)
		_trait_list = kwargs.pop('trait_list', None)
		super(DocumentForm, self).__init__(*args, **kwargs)
		self.fields['array'].widget = ListTextWidget(data_list=_array_list, name='array-list')
		self.fields['tissue'].widget = ListTextWidget(data_list=_tissue_list, name='tissue-list')
		self.fields['outcome'].widget = ListTextWidget(data_list=_trait_list, name='outcome-list')
		self.fields['exposure'].widget = ListTextWidget(data_list=_trait_list, name='exposure-list')

