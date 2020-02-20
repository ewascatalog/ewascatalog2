from django.db import models
from django.utils import timezone

class Study(models.Model):
    id = models.CharField(max_length=20, primary_key=True)
    study = models.CharField(max_length=20)
    author = models.CharField(max_length=20)
    pmid = models.CharField(max_length=20)
    analysis = models.CharField(max_length=20)

    class Meta:
        db_table = 'study'

    def __str__(self):
        return self.study
