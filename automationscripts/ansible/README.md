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
    ```
- Next, copy the playbook to run the ansible role:
    ```bash
    scp -r playbooks k8sclustinst:/home/ec2-user/
    ```

To run the docker-setup role:
--  
```bash  
ansible-playbook -i inventory.ini playbooks/docker-setup-run.yml
```

To run the kube-clust-setup role:
--  
```bash
ansible-playbook -i inventory.ini playbooks/kube-clust-cp-setup.yml
```