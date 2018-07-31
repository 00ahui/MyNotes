# Expose OpenSDS Cinder Compatiable API

### Create cinder service & endpoints

Check Openstack endpoints & services:

```shell
source /opt/stack/devstack/openrc admin admin
openstack endpoint list
openstack service list
```

Create Cinder API V3 service and endpoint:

```shell
openstack service create --name cinderv3 --description "Cinder V3" volumev3
openstack endpoint create --region RegionOne cinderv3 public 'http://172.31.40.129:8776/v3/$(project_id)s'
openstack endpoint list
```

### Build and run OpenSDS cindercompatibleapi

Set Openstack and OpenSDS endpoints:

```shell
export CINDER_ENDPOINT=http://172.31.40.129:8776/v3
export OPENSDS_ENDPOINT=http://172.31.40.129:50040
export OPENSDS_AUTH_STRATEGY=keystone
```

Build OpenSDS cindercompatibleapi:

```shell
go get github.com/opensds/opensds
go build -o cindercompatibleapi github.com/opensds/opensds/contrib/cindercompatibleapi
```


Run OpenSDS cindercompatibleapi:

```shell
./cindercompatibleapi &
```


### Test OpenSDS cinder API:

Set enviorment:

```shell
source /opt/stack/devstack/openrc admin admin
export CINDER_VERSION=3
export OS_VOLUME_API_VERSION=3
```


Execute cinder command:

```shell
osdsctl profile create '{"name": "default", "description": "default policy"}' 
osdsctl profile list
cinder type-list

osdsctl volume create 1 -n vol1
osdsctl volume list
cinder list

cinder create 1 --name vol2
cinder list
osdsctl volume list

cinder delete vol1
cinder delete vol2
cinder list
```



