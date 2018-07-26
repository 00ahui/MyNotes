
Requirments:

    opensds-1 & opensds-2
        - VM: m2.large (2U8G)
        - OS: ubuntu 16.04
        - Disk: >30GB


Configure /etc/hosts:

    172.31.10.16 opensds-1
    172.31.8.124 opensds-2


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
    sudo chmod 0500 /opt/opensds/bin/etcd /opt/opensds/bin/osdsdock /opt/opensds/bin/osdslet

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
    
    [keystone_authtoken]
    memcached_servers = opensds-N:11211
    auth_uri = http://opensds-N/identity
    auth_url = http://opensds-N/identity
    
    [osdsdock]
    api_endpoint = opensds-N:50051
    host_based_replication_driver = drbd
    
    [database]
    endpoint = opensds-1:62379,opesds-1:62380


Add  /etc/opensds/attacher.conf

    [osdsdock]
    api_endpoint = opensds-N:50051
    log_file = /var/log/opensds/osdsdock.log
    bind_ip = opensds-N
    dock_type = attacher
    
    [database]
    endpoint = opensds-1:62379,opensds-1:62380
    driver = etcd

Add /etc/opensds/drbd.yaml
    
    # Minumum and Maximum TCP/IP ports used for DRBD replication
    PortMin: 7000
    PortMax: 8000
    
    # Exactly two hosts between resources are replicated.
    Hosts:
       - Hostname: opensds-1
         IP: 172.31.10.16
         Node-ID: 1
    
       - Hostname: opensds-2
         IP: 172.31.8.124
         Node-ID: 2


Edit /etc/opensds/driver/lvm.yaml on opensds-1 :

    tgtBindIp:  172.31.10.16
    availabilityZone: az-1

Edit /etc/opensds/driver/lvm.yaml on opensds-2 :

    tgtBindIp:  172.31.8.124
    availabilityZone: az-2

Add /opt/opensds/bin/opensds-start on opensds-1:

    echo "starting opensds ..."
    VPCIP=`awk '/opensds-1/{print $1}' /etc/hosts`
    etcd --advertise-client-urls http://$VPCIP:62379 \
       --listen-client-urls http://$VPCIP:62379 \
       --listen-peer-urls http://$VPCIP:62380 \
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
   
    OPENSDS_ENDPOINT=http://127.0.0.1:50040
    OPENSDS_AUTH_STRATEGY=keystone
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
      status)
        opensds-status
        ;;
      *)
        echo "Usage: $NAME {start|stop|restart|status}" >&2
        exit 1
        ;;
    esac
    
    exit 0


Enable and start opensds service:
    
    chmod +x /etc/init.d/opensds
    systemctl enable opensds
    systemctl start opensds

    
Test replication:
    osdsctl volume create 1 -n vol-1 -a az-1
    osdsctl volume create 1 -n vol-2 -a az-2
    osdsctl volume list
    osdsctl replication create bd64a7f0-7120-43cd-beec-c85462d066fd 0a9ab17e-99df-486f-a005-7fa51faf9caa
    
