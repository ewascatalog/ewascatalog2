The website code can be found in the `website/` directory.

All that is missing from there is the downloadable
EWAS summary statistics file and `settings.env`.
These files are copied into position when the website
is setup in the project [Makefile](../Makefile).

## How to modify the website

The guts of the website are in `website/catalog`, mostly
in the `urls.py` and `views.py` files and the `templates` directory.
`urls.py` lists the web pages and references functions
in `views.py` that define the behavior of each page.
The the `views.py` functions link to the appropriate
html templates files in the `templates` directory.

## Origins of the website files

The basic template for the website was created using Django:
```
django-admin startproject website
```

The SECRET_KEY in `website/website/settings.py` was then copied
into `settings.env` for security reasons.

The `website/website/settings.py` file was then edited to its current form.

The `catalog` app was added.
```
cd website
python manage.py startapp catalog
```

The app was then added to the list of 'INSTALLED_APPS'
in `website/website/settings.py`.
```
INSTALLED_APPS = [
    ...
    'catalog',
]
```

Access to the database was tested:
```
python website/manage.py inspectdb
```

Additional files and code were added to the
`website/catalog` directory 
to define the EWAS Catalog website.







