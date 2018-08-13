### iCAT

Run docker:

```shell
docker pull irods/icat:4.0.3
docker run -p [port 1247 redirect]:1247 -v [irods home map dir]:/var/lib/irods -d -t irods/icat:4.0.3 [new rodsadmin password]

```

Setup postgresql:

```shell
echo 'host all all 172.18.0.0/16 md5' >> /etc/postgresql/9.3/main/pg_hba.conf
echo "listen_addresses = '*'" >> /etc/postgresql/9.3/main/postgresql.conf
/etc/init.d/postgresql restart
cat /etc/irods/irods.config | grep DATABASE_ADMIN_PASSWORD
```

Change iRODS admin password:

```shell
cat /etc/irods/irods.config | grep IRODS_ADMIN_PASSWORD
su - irods
iinit
ipasswd
```

