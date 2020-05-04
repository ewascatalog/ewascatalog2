from django import forms
from .models import Doc

class DocumentForm(forms.ModelForm):
    class Meta:
        model = Doc
        fields = ('name', 'email', 'studies', 'results', )