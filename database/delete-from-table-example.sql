-- docker exec -it dev.ewascatalog_db bash
-- start a mysql session (see settings.env for password) 
-- mysql -uroot -p${MYSQL_ROOT_PASSWORD} ewascatalog

# look at columns
SHOW COLUMNS FROM `studies`;
# check you can find the data you want to delete
SELECT * FROM studies WHERE author = 'Author A';
# delete it from results
DELETE FROM results WHERE study_id = '23456789_Author-A_a_trait';
# and then from studies
DELETE FROM studies WHERE study_id = '23456789_Author-A_a_trait';
