sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/manifests/*.yaml
sudo rm -rf /etc/kubernetes/pki
sudo rm -rf $HOME/.kube