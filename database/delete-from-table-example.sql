-- docker exec -it dev.ewascatalog_db bash
-- start a mysql session (see settings.env for password) 
-- mysql -uroot -p${MYSQL_ROOT_PASSWORD} ewascatalog

SHOW COLUMNS FROM `studies`;
DELETE FROM `studies` WHERE `study_id` = ;
SELECT array FROM `studies`;
