# Attach volumes to host

## Attach volumes to Linux via iSCSI LVM Driver 

### Prepare consumer VM

Apply EC2 instances with the following specs :
- VM: t2.micro (1U1G)
- OS: ubuntu 16.04
- Disk: OS 8GB gp2

Configure /etc/hosts :

```shell
172.31.10.16 opensds-1
172.31.8.124 opensds-2
172.31.5.103 consumer-1
```

Configure /etc/hostname :

```shell
consumer-1
```

### Install iscsi-initiator

```shell
sudo su - root
apt-get update
apt-get -y install open-iscsi
```

Edit /etc/iscsi/initiatorname.iscsi to change initiator name

```shell
InitiatorName=iqn.1993-08.org.debian:01:ea6b27c7caea
```


Edit /etc/iscsi/iscsid.conf

```shell
node.startup = automatic
```

# Attach volume to consumer-1 on OpenSDS host

```shell
source /opt/stack/devstack/openrc admin admin
osdsctl volume list

# create attachements
osdsctl volume attachment create '{
  "hostInfo": {
    "platform": "amd64",
    "osType": "Linux",
    "ip": "172.31.5.103",
    "host": "consumer-1",
    "initiator": "iqn.1993-08.org.debian:01:ea6b27c7caea"
  },
  "connectionInfo": {
    "driverVolumeType": "iscsi",
    "data": {},
    "additionalProperties": {}
  },
  "mountpoint": "",
  "volumeId": "a2a33917-1141-4f34-80ab-6c4f317d9451"
}'

osdsctl volume attachment list
osdsctl volume attachment show fff26bb7-3685-47d5-a22c-907f007b1c62

# LVM driver will automatic create tgt conf file to directory /etc/tgt/conf.d
cat /etc/tgt/conf.d/opensds-a2a33917-1141-4f34-80ab-6c4f317d9451.conf

<target iqn.2017-10.io.opensds:a2a33917-1141-4f34-80ab-6c4f317d9451>
        backing-store /dev/vg1/volume-a2a33917-1141-4f34-80ab-6c4f317d9451
        driver iscsi

        initiator-address 172.31.5.103
        initiator-name iqn.1993-08.org.debian:01:ea6b27c7caea
        write-cache on
</target>

# check the target using tgtadm command
tgtadm --lld iscsi --mode target --op show
```


### Discover OpenSDS iSCSI target on consumer-1

```shell
# discover target
iscsiadm -m discovery -t sendtargets -p 172.31.10.16

iscsiadm -m node

# login to iscsi target
iscsiadm -m node --login
iscsiadm -m session -o show

```