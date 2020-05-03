from __future__ import unicode_literals
from django.db import models
from django.utils import timezone

class Doc(models.Model):
    description = models.CharField(max_length=255, blank=True)
    document = models.FileField(upload_to='temp/')
    uploaded_at = models.DateTimeField(auto_now_add=True)
        
