# Install OpenSDS one node through ansible

https://github.com/opensds/opensds/wiki/OpenSDS-Cluster-Installation-through-Ansible

Note:
    Simplest way, but hard to understand
    Please review opensds-installer/ansible/roles/<roles>/scenarios for the details steps

# Install OpenSDS two nodes replication mannually

## Install OpenSDS

### Prepare two VMs

Apply two EC2 instances with the following specs :
- VM: m2.large (2U8G)
- OS: ubuntu 16.04
- Disk: 8GB


Configure /etc/hosts :

```shell
172.31.10.16 opensds-1
172.31.8.124 opensds-2
```

Configure /etc/hostname :

```shell
opensds-N
```

### Install OpenSDS on both nodes

Install dependency:

```shell
sudo apt update
sudo apt install make git gcc python sysstat -y
```

Run bootstrap scripts:

```shell
curl -sSL https://raw.githubusercontent.com/opensds/opensds/master/script/devsds/bootstrap.sh | sudo bash
```

Configure auth method:

```shell
cd $GOPATH/src/github.com/opensds/opensds
sudo sed -i 's/^OPENSDS_AUTH_STRATEGY=.*$/OPENSDS_AUTH_STRATEGY=keystone/' script/devsds/local.conf
```

Perform installation:

```shell
sudo script/devsds/install.sh
```

Copy executables:

```shell    
sudo cp build/out/bin/* /opt/opensds/bin/
```

### Test OpenSDS

Setup enviorment variables:

```shell
echo 'export PATH=$PATH:/opt/opensds/bin' | sudo tee -a /etc/profile
echo 'export OPENSDS_ENDPOINT=http://127.0.0.1:50040' | sudo tee -a /etc/profile
echo 'export OPENSDS_AUTH_STRATEGY=keystone' | sudo tee -a /etc/profile
source /etc/profile
source /opt/stack/devstack/openrc admin admin
```

Create volume:

```shell
osdsctl volume create 1 --name=test-001
```

List volume:

```shell
osdsctl volume list
```

# Setup replication

### Stop OpenSDS

Kill the processes to stop:

```shell
sudo killall etcd osdslet osdsdock
```

### Install DRBD

Add repository:

```shell
sudo add-apt-repository ppa:linbit/linbit-drbd9-stack
sudo apt-get update
```

Install DRBD:

```shell
sudo apt-get install drbd-utils python-drbdmanage drbd-dkms
```

### Edit configuration files

Edit /etc/opensds/opensds.conf
Set the database endpoint of both nodes to the IP of opensds-1

```shell    
[osdsdock]
host_based_replication_driver = drbd

[database]
endpoint = 172.31.10.16:62379,172.31.10.16:62380
```


Add  /etc/opensds/attacher.conf
Set the <ip address> to each node's individual IP address
Set the database endpoint of both nodes to the IP address of opensds-1

```shell
[osdsdock]
api_endpoint = <ip address>:50051
log_file = /var/log/opensds/osdsdock.log
bind_ip = <ip address>
dock_type = attacher

[database]
endpoint = 172.31.10.16:62379,172.31.10.16:62380
driver = etcd
```


Add /etc/opensds/drbd.yaml

```shell 
# Minumum and Maximum TCP/IP ports used for DRBD replication
PortMin: 7000
PortMax: 8000

# Exactly two hosts between resources are replicated.
Hosts:
   - Hostname: opensds-1
     IP: 172.31.10.16
     Node-ID: 0

   - Hostname: opensds-2
     IP: 172.31.8.124
     Node-ID: 1
```

Edit /etc/opensds/driver/lvm.yaml
Change the availability zone of opensds-2

```shell
availabilityZone: secondary
```

### Create startup scripts

Add /opt/opensds/bin/opensds-start on opensds-1

```shell
echo "starting opensds ..."
etcd --advertise-client-urls http://172.31.10.16:62379 \
   --listen-client-urls http://172.31.10.16:62379 \
   --listen-peer-urls http://172.31.10.16:62380 \
   --data-dir /opt/opensds/etcd/data \
   --debug >> /var/log/opensds/etcd.log 2>&1 &
sleep 1
osdslet &
osdsdock &
osdsdock --config-file /etc/opensds/attacher.conf &
```

Add /opt/opensds/bin/opensds-start on opensds-2

```shell
echo "starting opensds ..."
osdslet &
osdsdock &
osdsdock --config-file /etc/opensds/attacher.conf &
```
    
Add /opt/opensds/bin/opensds-status on both nodes

```shell
source /opt/stack/devstack/openrc admin admin
osdsctl dock list
```

Add /opt/opensds/bin/opensds-stop on opensds-1

```shell
killall etcd osdslet osdsdock
echo "opensds killed"
```

Add /opt/opensds/bin/opensds-stop on opensds-2

```shell
killall osdslet osdsdock
echo "opensds killed"
```

Change the priviledges

```shell    
chmod 0500 /opt/opensds/bin/opensds-*
```

### Register as system service


Add /etc/init.d/opensds

```shell
#!/bin/sh

### BEGIN INIT INFO
# Provides:           osdslet osdsdock
# Required-Start:     $network $local_fs
# Required-Stop:      $network $local_fs
# Default-Start:      2 3 4 5
# Default-Stop:       0 1 6
# Short-Description:  OpenSDS
### END INIT INFO

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:/usr/local/go/bin:/root/gopath/bin:/opt/opensds/bin"

case "$1" in
  start)
    opensds-start
    ;;
  stop)
    opensds-stop
    ;;
  restart)
    opensds-stop
    opensds-start
    ;;
  *)
    echo "Usage: $NAME {start|stop|restart}" >&2
    exit 1
    ;;
esac

exit 0
```

Enable and start opensds service:

```shell    
chmod +x /etc/init.d/opensds
systemctl enable opensds
systemctl start opensds
```

Check the dock status:

```shell
opensds-status
```
    
### Test replication:

Import admin enviorment variable:

```shell
source /opt/stack/devstack/openrc admin admin
```

Create two volumes:

```shell
osdsctl volume create 1 -n vol1
osdsctl volume create 1 -n vol2 -a secondary
osdsctl volume list
```

Create replication:

```shell
    osdsctl replication create 1a354244-dae6-4a5c-8464-8a105d318c17 c2bf2063-229b-4665-acc5-9761029bf6a4
    osdsctl replication list
```


# Install dashboard

### Install dependicy & build dashboard
 
https://github.com/opensds/opensds/tree/master/dashboard

### Configure ngnix and start dashboard

Edit  /etc/nginx/sites-available/default

```shell
server {
        listen 8088 default_server;
        listen [::]:8088 default_server;
        root /var/www/html;
        server_name OpenSDS;
                location /v3/ {
                proxy_pass http://172.31.10.16/identity/v3/;
        }

        location /v1beta/ {
                proxy_pass http://172.31.10.16:50040/v1beta/;
        }
}
```

Restart ngnix:

```shell
systemctl restart nginx
systemctl status nginx
```

Visit http://<dashboard_public_ip>:8088, login as admin, default password is opensds@123



# Use different backend storages


## Use LVM as backend storage

https://github.com/00ahui/MyNotes/blob/master/opensds/use-lvm-backend.md


## Use cinder as backend storage

https://github.com/00ahui/MyNotes/blob/master/opensds/use-cinder-backend.md


## Use ceph as backend storage

https://github.com/00ahui/MyNotes/blob/master/opensds/use-ceph-backend.md


## Use Huawei Dorado as backend storage

https://github.com/00ahui/MyNotes/blob/master/opensds/use-dorado-backend.md


# Integrate with different platforms


## Integrate with Kubernetes

https://github.com/00ahui/MyNotes/blob/master/opensds/integrate-kubernetes.md


## Integrate with Openstack

https://github.com/00ahui/MyNotes/blob/master/opensds/integrate-openstack.md

