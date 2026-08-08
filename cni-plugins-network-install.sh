#!/bin/bash 

# Ask user to run this script as non-root user:

if [  "$EUID" -eq "0" ]; then
    echo "Run the script as a non-root user!"
    exit 1;
fi


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
