
### Add host permision:

```shell
echo 'host all all 10.0.26.0/24 md5' >> /etc/postgresql/9.3/main/pg_hba.conf
echo "listen_addresses = '*'" >> /etc/postgresql/9.3/main/postgresql.conf
/etc/init.d/postgresql restart
```

### Create user and database

Create user and database

```shell
sudo -i -u postgres
psql
CREATE USER coolfsdba WITH PASSWORD 'coolfsdba';
CREATE DATABASE "coolfsdb";
GRANT ALL PRIVILEGES ON DATABASE "coolfsdb" TO coolfsdba;
```

List database

```shell
\d

SELECT datname FROM pg_database;

```shell 

Connect database as user

```shell
psql -h 172.18.0.2 -d coolfsdb -U coolfsdba -W
```

### Create and use table

Create and list table

```shell
create table test(id int, name varchar(32));

\dt

SELECT table_schema,table_name 
FROM information_schema.tables
ORDER BY table_schema,table_name;
```

Describe table:

```shell
\d+ test

select column_name, data_type, character_maximum_length
from INFORMATION_SCHEMA.COLUMNS
where table_name = 'test';
```


