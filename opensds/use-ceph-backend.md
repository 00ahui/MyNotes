# Use ceph as OpenSDS backend storage

## Install Ceph

### Prepare 1 VM  (or install directly on opensds-1 VM)

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


Configure tprofile and disable some features in ceph for kernel compatible.

```shell
ceph osd crush tunables hammer  # set crush tunables profile to hammer
grep -q "^rbd default features" /etc/ceph/ceph.conf || sed -i '/\[global\]/rbd default features = 1' /etc/ceph/ceph.conf  # 1: Layering support
```


### Test Ceph

Create a ceph pool:

```shell
ceph osd pool create pool0 100
ceph osd pool set pool0 size 1   # only 1 copy, just for test
```


Show the pool details:

```shell
ceph osd pool ls detail
```


## Use ceph as OpenSDS backend

### Install packages

```shell
sudo apt-get install python-rbd ceph-common
```

### Create configuration file

Copy /etc/ceph/ceph.conf from ceph-1:

```shell
sudo mkdir /etc/ceph
ssh -i KeyPair.pem ceph-1 cat /etc/ceph/ceph.conf | sudo tee /etc/ceph/ceph.conf
```

Copy admin authentication key from ceph-1:

```shell
ssh -i KeyPair.pem ceph-1 sudo ceph auth get-or-create client.admin | sudo tee /etc/ceph/ceph.client.admin.keyring
```

### Configure ceph as backend

Edit  /etc/opensds/opensds.conf

```shell
[osdsdock]
enabled_backends = ceph

[ceph]
name = ceph
description = Ceph Driver
driver_name = ceph
config_path = /etc/opensds/driver/ceph.yaml
```

Edit /etc/opensds/driver/ceph.yaml

```shell
configFile: /etc/ceph/ceph.conf
pool:
  pool0: # ceph pool name
    storageType: block
    availabilityZone: az2
    extras:
      dataStorage:
        provisioningPolicy: Thin
        isSpaceEfficient: true
      ioConnectivity:
        accessProtocol: rbd
        maxIOPS: 6000000
        maxBWS: 500
      advanced:
        diskType: SSD
        latency: 5ms
```

Restart OpenSDS:

```shell
sudo su - root
opensds-stop
opensds-start
opensds-status
```

### Test ceph backend (still failed)

Show ceph pools:

```shell
source /opt/stack/devstack/openrc admin admin
osdsctl pool list
```


Create volume:

```shell
osdsctl volume create 1 -n vol5 -a az2
osdsctl volume list
```

Check ceph volume
```shell
rbd ls pool0 
```

Delete volume:

```shell
osdsctl volume delete ae87d5a5-0314-46a4-9df5-13d32d604578
osdsctl volume list
```


