## Linux commands quick reference:

1. Upload files / folders:  
    
    ```bash 
    scp -r inventory.ini k8sclustinst:/home/ec2-user/
    ```
2. Download files / folders:  
    ```bash 
    scp -r k8sclustinst:/home/ec2-user/docker-setup .
    ```

3. Install ansible:
    ```bash
    sudo yum install ansible -y

    or 

    sudo apt install ansible-core -y
    ```
### Ansible setup:
Master node:
- Copy over the contents of `inventory.ini` into `/etc/ansible/hosts` 
    - `hosts` is the file. If not present, create it - only on master node
    ```bash
    scp -r inventory.ini k8sclustinst:/home/ec2-user/
    ```
- Copy on the Ansible role you prepared (e.g. `docker-setup`) in the `/home/ec2-user/` directory  

    ```bash
    scp -r docker-setup k8sclustinst:/home/ec2-user/

    scp -r kube-clust-setup k8sclustinst:/home/ec2-user
    ```
- Next, copy the playbook to run the ansible role:
    ```bash
    scp -r playbooks k8sclustinst:/home/ec2-user/
    ```
- Remember to transfer your shell scripts and place them in `<ansible_role>/files`
    ```bash
    scp -r ../../cni-plugins-network-install.sh ../../control-plane_clust-init-private.sh k8sclustinst:/home/ec2-user
    ```
- For executing commands on remote worker nodes, place the pem file in a suitable location on master node. Set its permission to '0600' to use it in ansible.
    ```bash
    scp ../../devops-app-key-01.pem k8sclustinst:/home/ec2-user

    chmod u=+r,o=-rwx,g=-rwx devops-app-key-01.pem
    ```
To run the docker-setup role:
--  
```bash  
ansible-playbook -i inventory.ini playbooks/docker-setup-run.yml
```

To run the kube-clust-setup role:
--  
```bash
ansible-playbook -i inventory.ini playbooks/kube-clust-setup-run.yaml --skip-tags "node-setup,node-network-setup,post-setup"

ansible-playbook -i inventory.ini -l cpnodes playbooks/kube-clust-setup-run.yaml --tags "node-setup"

ansible-playbook -i inventory.ini -l workers playbooks/kube-clust-setup-run.yaml --tags "post-setup"
```

- Copy output and paste it in vars/main.yml 
    - if not already there, create new variable - `kubeadm_join_cmd` and then paste the below command output as value to this variable.  
`kubeadm token create --print-join-command` 

```
ansible-playbook -i inventory.ini -l workers playbooks/kube-clust-setup-run.yaml --tags "node-network-setup"
```

To move the admin.conf file from primary control node to all worker nodes & setup kubeconfig (required to access `kubectl` from worker nodes):
```bash 
ansible-playbook -i inventory.ini -l workers playbooks/kube-clust-setup-run.yaml --tags "post-setup"
```