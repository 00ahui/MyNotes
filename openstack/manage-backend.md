### manage cinder-volume services

List backends:

```shell 
cinder service-list
```

Disable and remove a backend:

```shell
sudo su - stack

cinder service-disable openstack-1@ceph cinder-volume
mysql -e "update services set deleted = 1 where host like 'openstack-1@ceph' and disabled = 1 " cinder
```