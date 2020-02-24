The website code can be found in `website/`.
All that this missing from there is the downloadable
EWAS summary statistics file and `settings.env`.
These files are copied into position when the website
is setup in the project `Makefile`.

## How to modify the website

The guts of the website are in `website/catalog`, mostly
in the `urls.py` and `views.py` files and the `templates` directory.
`urls.py` lists the web pages and references functions
in `views.py` that define the behavior of each page.
The the `views.py` functions link to the appropriate
html templates files in the `templates` directory.

## Origins of the website files

The basic template for the website was created using the following django command:
```
django-admin startproject website
```

The SECRET_KEY in `website/website/settings.py` was then copied
to the file `../settings.env` for security reasons.

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


## Debugging Python access to the database

Below is code for logging in to the database in Python
and showing the first p-value for CpG site 'cg00029284'
(*Note:* The value for "password" is
the value `DATABASE_PASSWORD` in the file `settings.env`). 
```
import MySQLdb
import MySQLdb.cursors
db = MySQLdb.connect(host="127.0.0.1",user="ewas",password="password",db="ewascatalog")
cur = db.cursor();
cur.execute("select studies.*,results.* from results join studies on results.study_id=studies.study_id where cpg='cg00029284'")
cols = [x[0] for x in cur.description]
data = cur.fetchall();
data[1][cols.index("p")] 
```					







