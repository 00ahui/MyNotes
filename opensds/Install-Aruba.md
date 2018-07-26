
Requirments:

opensds-1
- VM: m2.large (2U8G)
- OS: ubuntu 16.04
- Disk: >30GB


Install dependency:

    sudo apt update
    sudo apt install make git gcc python

Run bootstrap scripts:

    curl -sSL https://raw.githubusercontent.com/opensds/opensds/master/script/devsds/bootstrap.sh | sudo bash

Configure auth method:

    cd $GOPATH/src/github.com/opensds/opensds
    sudo sed -i 's/^OPENSDS_AUTH_STRATEGY=.*$/OPENSDS_AUTH_STRATEGY=keystone/' script/devsds/local.conf

Perform installation:

    sudo script/devsds/install.sh
    