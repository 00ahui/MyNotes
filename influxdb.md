# Influxdb commands

Create user:

```shell
curl -XPOST "http://localhost:8086/query" --data-urlencode "q=CREATE USER root WITH PASSWORD 'huawei' WITH ALL PRIVILEGES"
```

```shell
influx -username 'root' -password 'huawei'
show databases
```

Insert data:

```shell
curl -i -XPOST 'http://8.44.72.211:8086/write?db=telegraf' --data-binary 'disk,host="oltp" iops=1000,lat=10'
curl -i -XPOST 'http://8.44.72.211:8086/write?db=telegraf' --data-binary @data.txt
```


# Telegraf

## Test configuration file

```shell
 /usr/bin/telegraf -config /etc/telegraf/telegraf.conf -config-directory /etc/telegraf/telegraf.d -test --input-filter snmp
```

## SNMP diagnose

Test SNMP V2

```shell
snmpget -v 2c -c <read_community> <controler_ip> SNMPv2-MIB::sysName.0
snmpwalk -v 2c -c <read_community> <controler_ip> HUAWEI-STORAGE-HARDWARE-MIB::hwInfoControllerID
snmptable -v 2c -c <read_community> <controler_ip> HUAWEI-STORAGE-HARDWARE-MIB::hwInfoControllerTable
snmpbulkget -Cr20 -v 2c -c <read_community> <controler_ip> ISM-PERFORMANCE-MIB::hwPerfLunTotalIOPS

```

Test SNMP V2

```shell
snmpget -v3  -l authPriv -u telegraf -a SHA -A 'Admin_storage1' -x AES -X 'Admin_storage3' 8.44.72.143 SNMPv2-MIB::sysName.0
```

Dump request and response

```shell
tcpdump -s 0 -vvv -i ens192 port 161
```
