sudo kubeadm reset -f # --ignore-preflight-errors=all

# Manually run below remove commands if above kubeadm reset command gets stuck in 'context deadline exceeded' error
sudo rm -rf /etc/kubernetes/manifests/*.yaml
sudo rm -rf /etc/kubernetes/pki
sudo rm -rf $HOME/.kube
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/kubelet/*

sudo rm -rf /etc/kubernetes

# Cleanup Calico installations: 
sudo rm -rf /etc/cni/net.d
sudo rm -rf /var/lib/cni/

