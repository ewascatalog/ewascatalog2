from django import forms
from django.conf import settings
from .models import Doc
from . import textquery, structuredquery, database, upload

# class DocumentForm(forms.ModelForm):
#     class Meta:
#         model = Doc
#         fields = ('name', 'email', 'studies', 'results', )

class StudyForm(forms.Form):
	db = database.default_connection()
	
class ListTextWidget(forms.TextInput):
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
	name = forms.CharField(required=True)
	email = forms.EmailField()
	array = forms.CharField(required=True)
	tissue = forms.CharField(required=True)
	results = forms.FileField()
	def __init__(self, *args, **kwargs):
		_array_list = kwargs.pop('array_list', None)
		_tissue_list = kwargs.pop('tissue_list', None)
		super(DocumentForm, self).__init__(*args, **kwargs)
		self.fields['array'].widget = ListTextWidget(data_list=_array_list, name='array-list')
		self.fields['tissue'].widget = ListTextWidget(data_list=_tissue_list, name='tissue-list')
