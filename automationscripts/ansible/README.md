## Linux commands quick reference:

1. Upload files / folders:  
    
    ```bash 
    scp -r inventory.ini k8sclustinst:/home/ec2-user/
    ```
2. Download files / folders:  
    ```bash 
    scp -r k8sclustinst:/home/ec2-user/docker-setup .
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

To run the docker-setup role:
--
```bash  
ansible-playbook playbooks/docker-setup-run.yml
```