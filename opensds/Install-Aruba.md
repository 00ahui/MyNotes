
Requirments:

    opensds-1 & opensds-2
        - VM: m2.large (2U8G)
        - OS: ubuntu 16.04
        - Disk: >30GB


Configure /etc/hosts:

    172.31.10.16 opensds-1
    172.31.8.124 opensds-2


Configure /etc/hostname:

    opensds-N

Install on opensds-1 & opensds-2


Install dependency:

    sudo apt update
    sudo apt install make git gcc python sysstat -y

Run bootstrap scripts:

    curl -sSL https://raw.githubusercontent.com/opensds/opensds/master/script/devsds/bootstrap.sh | sudo bash

Configure auth method:

    cd $GOPATH/src/github.com/opensds/opensds
    sudo sed -i 's/^OPENSDS_AUTH_STRATEGY=.*$/OPENSDS_AUTH_STRATEGY=keystone/' script/devsds/local.conf

Perform installation:

    sudo script/devsds/install.sh

Copy executables:
    
    sudo cp build/out/bin/* /opt/opensds/bin/

Test OpenSDS:
    
    echo 'export PATH=$PATH:/opt/opensds/bin' | sudo tee -a /etc/profile
    echo 'export OPENSDS_ENDPOINT=http://127.0.0.1:50040' | sudo tee -a /etc/profile
    echo 'export OPENSDS_AUTH_STRATEGY=keystone' | sudo tee -a /etc/profile
    source /etc/profile
    source /opt/stack/devstack/openrc admin admin
    osdsctl volume create 1 --name=test-001
    osdsctl volume list

Install DRBD:
    
    sudo add-apt-repository ppa:linbit/linbit-drbd9-stack
    sudo apt-get update
    sudo apt-get install drbd-utils python-drbdmanage drbd-dkms

Stop OpenSDS
    
    sudo killall etcd osdslet osdsdock

Edit /etc/opensds/opensds.conf
    
    [osdsdock]
    host_based_replication_driver = drbd
    
    [database]
    endpoint = 172.31.10.16:62379,172.31.10.16:62380


Add  /etc/opensds/attacher.conf

    [osdsdock]
    api_endpoint = <ip address>:50051
    log_file = /var/log/opensds/osdsdock.log
    bind_ip = <ip address>
    dock_type = attacher
    
    [database]
    endpoint = 172.31.10.16:62379,172.31.10.16:62380
    driver = etcd

Add /etc/opensds/drbd.yaml
    
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

Edit /etc/opensds/driver/lvm.yaml on opensds-2 :

    availabilityZone: secondary

Add /opt/opensds/bin/opensds-start on opensds-1:

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
    
    
Add /opt/opensds/bin/opensds-start on opensds-2:

    echo "starting opensds ..."
    osdslet &
    osdsdock &
    osdsdock --config-file /etc/opensds/attacher.conf &

    
Add /opt/opensds/bin/opensds-status :

    source /opt/stack/devstack/openrc admin admin
    osdsctl dock list


Add /opt/opensds/bin/opensds-stop :

    killall etcd osdslet osdsdock
    echo "opensds killed"


Change the priviledges :
    
    chmod 0500 /opt/opensds/bin/opensds-*


Add /etc/init.d/opensds :

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


Enable and start opensds service:
    
    chmod +x /etc/init.d/opensds
    systemctl enable opensds
    systemctl start opensds
    opensds-status

    
Test replication:

    source /opt/stack/devstack/openrc admin admin
    osdsctl volume create 1 -n vol1
    osdsctl volume create 1 -n vol2 -a secondary
    osdsctl volume list
    osdsctl replication create 1a354244-dae6-4a5c-8464-8a105d318c17 c2bf2063-229b-4665-acc5-9761029bf6a4
    osdsctl replication list
    
