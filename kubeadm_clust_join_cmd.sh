
## Stuff done for worker nodes:
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.d/k8s.conf
sudo sysctl --system

# Next, copy over the admin.conf file from Control Plane to Worker Node

# Next, follow the Calico installation steps from control-plane_clust-init-private.sh till custom-resources.yaml deployment

# then run join command:

kubeadm join 10.0.0.235:6443 --token k0kd46.4gn04xn9fyol9zud \
    --discovery-token-ca-cert-hash sha256:87b42daf3ce80167c96e47b610794f5a92dfd6fd0a936ae7ca63ee655e4e3804 