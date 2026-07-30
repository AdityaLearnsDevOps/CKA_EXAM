#!/bin/bash 

# Ask user to run this script as non-root user:

if [  "$EUID" -eq "0" ]; then
    echo "Run the script as a non-root user!"
    exit 1;
fi

## Search for default interface on the machine
DEFAULT_ETH_INTERFACE=$(ip route show | awk '/default / {print $5}')

## Get the IP address from the default interface on the machine 
PRIVATE_IP_ADDR=$(ip addr show $DEFAULT_ETH_INTERFACE | awk '/inet / {print $2}' | cut -d/ -f1)

## To get the Public IP address from within the machine, use:
# PUBLIC_IP_ADDR=$(curl ifconfig.me)

# API Server Advertise Address 
## Helping to choose Kubernetes the correct network interface on the machine 
APISERV_ADVERTISE_ADDR="$PRIVATE_IP_ADDR"


# Pod Network CIDR must never overlap Kubernetes AWS Instance VPC CIDR ranges
## We are going to use Calico as CNI Plugin.
## Calico suggests to give 192.168.0.0/16
POD_NET_CIDR=192.168.0.0/16 

# Set ip_forward = 1 :
# Why? 
## Pod traffic gets routed through the node (bridge → node's network stack → other nodes). 
## Without ip_forward=1, the kernel drops packets not destined for the node itself 
##   — kills pod-to-pod routing before it even starts.

echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
sudo sysctl --system


## Configure kubeconfig:

mkdir -p $HOME/.kube/

# Run kubeadm init with high verbose output:
sudo kubeadm init \
    --v=5 \
    --apiserver-advertise-address="$APISERV_ADVERTISE_ADDR" \
    --pod-network-cidr="$POD_NET_CIDR"

    
sleep 5s


sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown -R $(id -u):$(id -g) $HOME/.kube/config


############# CNI Plugin for POD NETWORK INSTALL ############

## APNAMBIA: recheck whether below commands worked 
### Would need to rerun below again:

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/v1_crd_projectcalico_org.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/tigera-operator.yaml

sleep 5s

# Below URL received when we want to customize Calico install (click on 'iptables' on the website installation guide)
# Downlaod custom-resources.yaml

curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/custom-resources.yaml

# Create a Manifest to install Calico:

kubectl create -f custom-resources.yaml


## Load Kernel modules:

sudo modprobe nf_conntrack
echo "nf_conntrack" | sudo tee -a /etc/modules-load.d/k8s.conf
