#!/bin/bash

# Ask user to run this script as non-root user:

if [  "$EUID" -eq "0" ]; then
    echo "Run the script as a non-root user!"
    exit 1;
fi


############# CNI Plugin for POD NETWORK INSTALL ############
# Set ip_forward = 1 :
# Why? 
## Pod traffic gets routed through the node (bridge → node's network stack → other nodes). 
## Without ip_forward=1, the kernel drops packets not destined for the node itself 
##   — kills pod-to-pod routing before it even starts.

echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
sudo sysctl --system


## APNAMBIA: recheck whether below commands worked 
### Would need to rerun below again:

kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/v1_crd_projectcalico_org.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/tigera-operator.yaml

sleep 5s

# Below URL received when we want to customize Calico install (click on 'iptables' on the website installation guide)
# Downlaod custom-resources.yaml

#curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.32.1/manifests/custom-resources.yaml

## For Debian, we are creating our own custom-resources.yaml for Calico.. taking the URL version as base:

cat <<EOF > /tmp/custom.resources.yaml
# This section includes base Calico installation configuration.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
  calicoNetwork:
    ipPools:
      - name: default-ipv4-ippool
        blockSize: 26
        cidr: 192.168.0.0/16
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
    nodeAddressAutodetectionV4:
        kubernetes: NodeInternalIP

---
# This section configures the Calico API server.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}

---
# Configures the Calico Goldmane flow aggregator.
apiVersion: operator.tigera.io/v1
kind: Goldmane
metadata:
  name: default

---
# Configures the Calico Whisker observability UI.
apiVersion: operator.tigera.io/v1
kind: Whisker
metadata:
  name: default
EOF

# Create a Manifest to install Calico:

kubectl create -f /tmp/custom-resources.yaml


## Load Kernel modules:

sudo modprobe nf_conntrack
echo "nf_conntrack" | sudo tee -a /etc/modules-load.d/k8s.conf
