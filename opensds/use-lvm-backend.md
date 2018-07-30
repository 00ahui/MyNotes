# Use cinder as OpenSDS backend storage

### Create volume group

Edit /etc/lvm/lvm.conf, add the device into $global_filter

```shell
# filter only loop3 & xvdb1
global_filter = [ "a|loop3|", "a|/dev/xvdb1|", "r|.*|" ]
```

Create volume group:

```shell
pvcreate /dev/xvdb1
vgcreate vg1 /dev/xvdb1
```


### Configure LVM backend

Edit /etc/opensds/driver/lvm.yaml, add the volume group:

```shell
tgtBindIp: 172.31.10.16
tgtConfDir: /etc/tgt/conf.d
pool:
  vg1:
    diskType: NL-SAS
    availabilityZone: az0
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
        latency: 5ms
```

Restart OpenSDS:

```shell
opensds-stop
opensds-start
```

Check the pool:

```shell
source /opt/stack/devstack/openrc admin admin
osdsctl pool list
```

### Use LVM backend

Create volume:

```shell
osdsctl volume create 1 -n vol3 -a az0
osdsctl volume list
lvs
```

Delete volume:

```shell
osdsctl volume delete f162ab16-db5b-4ee6-b213-35a1d7b4755d
osdsctl volume list
lvs
```