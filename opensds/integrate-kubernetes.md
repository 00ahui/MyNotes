# Integrate OpenSDS with kubernetes

## Integrate through CSI

### Prepare VM

Apply EC2 instances with the following specs :
- VM: t2.xlarge (4U16G)
- OS: ubuntu 16.04
- Disk: OS 8GB gp2, Data 10GB (mount to /home)

Install dependency packages:

```shell
sudo apt update
sudo apt install git curl wget make gcc zip sysstat libltdl7
```

Install Golang:

```shell
wget https://storage.googleapis.com/golang/go1.9.2.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.9.2.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' | sudo tee -a /etc/profile
echo 'export GOPATH=$HOME/gopath' | sudo tee -a /etc/profile
source /etc/profile
go version
```

Install docker:

```shell
wget https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_18.03.1~ce-0~ubuntu_amd64.deb
sudo dpkg -i docker-ce_18.03.1~ce-0~ubuntu_amd64.deb
sudo docker version
```

### Kubernetes Local Cluster Deployment

Install etcd:

```shell
wget https://github.com/coreos/etcd/releases/download/v3.3.0/etcd-v3.3.0-linux-amd64.tar.gz
tar -xzf etcd-v3.3.0-linux-amd64.tar.gz
cd etcd-v3.3.0-linux-amd64
sudo cp -f etcd etcdctl /usr/local/bin/
```

Build kubernete (very long time):

```shell
cd $HOME
git clone https://github.com/kubernetes/kubernetes.git
cd kubernetes
git checkout v1.10.0
make
echo alias kubectl="$HOME/kubernetes/cluster/kubectl.sh" | sudo tee -a /etc/profile
```

Run kubernetes:

```shell
sudo su - root
cd /home/ubuntu/kubernetes
ALLOW_PRIVILEGED=true \
FEATURE_GATES=CSIPersistentVolume=true,MountPropagation=true \
RUNTIME_CONFIG="storage.k8s.io/v1alpha1=true" \
LOG_LEVEL=5 \
hack/local-up-cluster.sh
```

NOTE: next time can run with output:

```shell
ALLOW_PRIVILEGED=true \
FEATURE_GATES=CSIPersistentVolume=true,MountPropagation=true \
RUNTIME_CONFIG="storage.k8s.io/v1alpha1=true" \
LOG_LEVEL=5 \
hack/local-up-cluster.sh -o _output/local/bin/linux/amd64/
```

NOTE: if etcd is already running, comment all etcd in hack/local-up-cluster.sh

```shell
# validate that etcd is: not running, in path, and has minimum required version.
#if [[ "${START_MODE}" != "kubeletonly" ]]; then
  #kube::etcd::validate
#fi

echo "Starting services now!"
if [[ "${START_MODE}" != "kubeletonly" ]]; then
  #start_etcd

  # Check if the etcd is still running
  #[[ -n "${ETCD_PID-}" ]] && kube::etcd::stop
  #[[ -n "${ETCD_DIR-}" ]] && kube::etcd::clean_etcd_dir
```

### Build NBP binary

Download and build opensds nbp:

```shell
go get github.com/opensds/nbp
cd $GOPATH/src/github.com/opensds/nbp
make
```

Create target dir and copy binaries:

```shell
sudo mkdir /opt/opensds-nbp-linux-amd64
sudo mkdir /opt/opensds-nbp-linux-amd64/csi
sudo mkdir /opt/opensds-nbp-linux-amd64/provisioner
sudo mkdir /opt/opensds-nbp-linux-amd64/flexvolume
sudo cp -r csi/server/deploy /opt/opensds-nbp-linux-amd64/csi
sudo cp -r csi/server/examples /opt/opensds-nbp-linux-amd64/csi
sudo cp .output/flexvolume.server.opensds /opt/opensds-nbp-linux-amd64/flexvolume/opensds
sudo cp -r opensds-provisioner/deploy /opt/opensds-nbp-linux-amd64/provisioner
sudo cp -r opensds-provisioner/examples /opt/opensds-nbp-linux-amd64/provisioner
```



### Run CSI

Edit /opt/opensds-nbp-linux-amd64/csi/deploy/kubernetes/csi-configmap-opensdsplugin.yaml

```shell
data:
  opensdsendpoint: http://172.31.40.129:50040
  osauthurl: http://172.31.40.129/identity
```

Run CSI PODs:

```shell
sudo su - root
cd /opt/opensds-nbp-linux-amd64/csi
kubectl create -f deploy/kubernetes
kubectl get pods
```
### Test CSI

Create a OpenSDS profile (optional: or use default):

```shell
source /opt/stack/devstack/openrc admin admin

osdsctl profile list

osdsctl profile create '{
    "name": "Gold",
    "description":"Profile for kubernetes CSI storage class", 
    "extras": {
        ":provisionPolicy": {
            "dataStorageLoS": {
                "provisioningPolicy": "Thin"
            },
            "ioConnectivityLoS": {
                "accessProtocol": "RBD"
            }
        }
    }
}'
```

Test the profile:

```shell
osdsctl volume create 1 -n test01 -p 21b9fcc4-8b31-4a6a-a83c-e6eb24ce1377
osdsctl volume list
osdsctl volume delete 99d4a810-dde2-428e-a719-3395c79866de
```

Create a pod using nginx example: 

Edit examples/kubernetes/nginx.yaml, change provisioner, add "profile" parameter for StorageClass:

```shell
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: csi_sc_gold
provisioner: csi-provisioner-opensdsplugin-0
parameters:
 profile: c6a65e0b-7dbb-4e93-88c3-c651d79902fd
```

Create nginx pod (still not success):

```shell
kubectl create -f examples/kubernetes/nginx.yaml
```

NOTE: if fails, before retry, delete existing nginx pod, pvc, sc

```shell
kubectl get pod
kubectl delete pod nginx
kubectl get pvc
kubectl delete pvc csi-pvc-opensdsplugin
kubectl get sc
kubectl delete sc csi-sc-opensdsplugin
```

or just:

```shell
kubectl delete -f examples/kubernetes/nginx.yaml
```