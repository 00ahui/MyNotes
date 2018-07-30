# Use cinder as OpenSDS backend storage

## Install openstack using devstack

### Prepare 1 VM

Apply an EC2 instance with the following specs :
- VM: m2.large (2U8G)
- OS: ubuntu 16.04
- Disk: 8GB

Configure /etc/hosts:

```shell
172.31.36.154 openstack-1
```

Configure /etc/hostname:

```shell
openstack-1
```

### Install OpenStack on openstack-1

Install dependency:

```shell
sudo apt update
sudo apt install make git gcc python sysstat -y
```

Setup openstack using devstack: 

https://docs.openstack.org/devstack/latest/


### Test cinder

Import enviorment variables:

```shell
source /opt/stack/devstack/openrc admin admin
```

List volume type:

```shell
cinder type-list
```

Create a volume:

```shell
cinder create 1 --name volume001
```

List volumes:

```shell
cinder list
```

Delete the volume:

```shell
cinder delete e13d9db6-0ea5-42bf-adaa-2f52b642c340
```

## Create custom cinder backends

### Delete default LVM backend

Delete default volume-type:

```shell
cinder type-list
cinder type-delete 6adf8fb4-cccf-4846-b13e-c654656cc4b7
```

Disalbe default backend:

```shell
cinder service-list
cinder service-disable openstack-1@lvmdriver-1 cinder-volume
```


Delete backend in cinder database:

```shell
sudo su - stack
mysql -e "update services set deleted = 1 where host like 'openstack-1@lvmdriver-1' and disabled = 1 " cinder
```

### Create a custom LVM cinder backend

Create volume group:

```shell
sudo pvcreate /dev/xvdb1
sudo vgcreate vg1 /dev/xvdb1
```

Edit /etc/cinder/cinder.conf

```shell
[DEFAULT]
default_volume_type = lvm
enabled_backends = vg1

[vg1]
image_volume_cache_enabled = True
volume_clear = zero
lvm_type = auto
target_helper = tgtadm
volume_group = vg1
volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_backend_name = vg1
```


Restart cinder-volume service:

```shell
sudo systemctl restart devstack@c-vol.service
cinder service-list
```

### Test the backend

Create volume-type:

```shell
cinder type-create lvm
cinder type-key lvm set volume_backend_name=vg1
cinder extra-specs-list
```

Test volume-type:

```shell
cinder create 1 --name lvm001
cinder list
cinder delete lvm001
```

Show cinder pool (will use in OpenSDS):

```shell
cinder get-pools
```
 

## Use cinder as the backend of OpenSDS

### Configure OpenSDS

Logoin to opensds-1

Edit /etc/opensds/opensds.conf :

```shell
[cinder]
name = cinder
description = Cinder Test
driver_name = cinder
config_path = /etc/opensds/driver/cinder.yaml

[osdsdock]
enabled_backends = lvm,cinder
```

Edit /etc/opensds/driver/cinder.yaml :

```shell
authOptions:
  endpoint: "http://172.31.36.154/identity"
  domainName: "Default"
  username: "admin"
  password: "secret"
  tenantName: "admin"
pool:
  openstack-1@vg1#vg1:
    storageType: block
    availabilityZone: az1
    extras:
      dataStorage:
        provisioningPolicy: Thin
        isSpaceEfficient: false
      ioConnectivity:
        accessProtocol: iscsi
        maxIOPS: 7000000
        maxBWS: 600
      advanced:
        diskType: SSD
        latency: 3ms
```

Restart opensds to enable cinder backend:

```shell
sudo su - root
opensds-stop
opensds-start
opensds-status
```

### Test cinder backend

Show cinder pools:

```shell
source /opt/stack/devstack/openrc admin admin
osdsctl pool list
```

Create volume:

```shell
osdsctl volume create 1 -n vol3 -a az1
osdsctl volume list
```

Login to openstack-1, check the cinder volume
```shell
source /opt/stack/devstack/openrc admin admin
cinder list
```

Delete volume:

```shell
osdsctl volume delete ae87d5a5-0314-46a4-9df5-13d32d604578
```