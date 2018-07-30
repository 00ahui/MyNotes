### Delete pool

Edit /etc/ceph/ceph.conf

```shell
[mon]
mon allow pool delete = true
```
Restart ceph mon:

```shell
systemctl restart ceph-mon.target
```

Delete Pool
```shell
ceph osd pool delete vms vms --yes-i-really-really-mean-it
```
