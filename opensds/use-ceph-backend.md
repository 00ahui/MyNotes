
## Install Ceph

### Prepare 1 VM

Apply an EC2 instance with the following specs :
- VM: m2.large (2U8G)
- OS: ubuntu 16.04
- Disk: /dev/xvda 8GB gp1, /dev/xvdb 100GB magnet

Configure /etc/hosts:

```shell
172.31.39.170 ceph-1
```

Configure /etc/hostname:

```shell
ceph-1
```

### Install Ceph on ceph-1

Install dependency:

```shell
sudo apt update
sudo apt install make git gcc python python-pip sysstat -y
```
    
Install ansible:

```shell
sudo add-apt-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

Clone repository:

```shell
sudo su - root
git clone https://github.com/ceph/ceph-ansible.git
```

Prepare requirements:

```shell
cd ceph-ansible
pip install -r requirements.txt
```

Edit group_vars/all.yml

```shell
ceph_origin: repository
ceph_repository: community
ceph_stable_release: luminous
public_network: "172.31.32.0/20"
cluster_network: "{{ public_network }}"
monitor_interface: eth0
devices:
    - '/dev/xvdb'
osd_scenario: collocated
```

Edit local.hosts

```shell
[mons]
localhost ansible_connection=local

[osds]
localhost ansible_connection=local

[mgrs]
localhost ansible_connection=local
```

Run ansible-playbook:

```shell
cp site.yml.sample site.yml
ansible-playbook site.yml -i local.hosts
```

### Test Ceph

Create a ceph pool:

```shell
ceph osd pool create pool1 64
```
Show the pool details:

```shell
ceph osd pool ls detail
```

## Configure Ceph as cinder backend

### Prepare configuration file

Configure /etc/hosts for both openstack-1 and ceph-1:

```shell
172.31.36.154 openstack-1 
172.31.39.170 ceph-1
```

Copy EC2 KeyPair.pem to both hosts, change the permission of the file:

```shell
chmod 0400 KeyPair.pem
```

On openstack-1, copy /etc/ceph/ceph.conf from ceph-1:

```shell
sudo mkdir /etc/ceph
ssh -i KeyPair.pem ceph-1 cat /etc/ceph/ceph.conf | sudo tee /etc/ceph/ceph.conf
```

On ceph-1 create pools

```shell
sudo su - root
ceph osd pool create volumes 64
ceph osd pool create vms 64
ceph osd pool create images 64

rbd pool init volumes
rbd pool init vms
rbd pool init images
```

On ceph-1 set the cinder authentication

```shell
#ceph auth get-or-create client.cinder mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=volumes, allow rwx pool=vms, allow rwx pool=images'
ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images'
```

On openstack-1, connect ceph-1 to generate authentication key and save it to /etc/ceph/ceph.client.cinder.keyring

```shell
ssh -i KeyPair.pem ceph-1 sudo ceph auth get-or-create client.cinder | sudo tee /etc/ceph/ceph.client.cinder.keyring
sudo chown stack:stack /etc/ceph/ceph.client.cinder.keyring
```

### Configure cinder backend on openstack-1

Install ceph packages :

```shell
sudo apt-get install ceph-common python-rbd
```

Edit /etc/cinder/cinder.conf :

```shell
[DEFAULT]
default_volume_type = ceph
enabled_backends = rbd

[rbd]
volume_driver = cinder.volume.drivers.rbd.RBDDriver
volume_backend_name = rbd
rbd_pool = volumes
rbd_ceph_conf = /etc/ceph/ceph.conf
rbd_flatten_volume_from_snapshot = false
rbd_max_clone_depth = 5
rbd_store_chunk_size = 4
rados_connect_timeout = -1
rbd_user = cinder
rbd_secret_uuid = 3117e7a5-a38d-4770-87c8-e35fe1f7af77
```

Restart cinder-volume:

```shell
sudo systemctl restart devstack@c-vol.service
```

Import admin enviorment variables:

```shell
source /opt/stack/devstack/openrc admin admin
```
List backends:

```shell
cinder service-list    
```

Create volume type:

```shell
cinder type-create ceph
cinder type-key ceph set volume_backend_name=ceph
cinder extra-specs-list
```

Create volume:

    cinder create 1 --name volume001 --volume_type ceph