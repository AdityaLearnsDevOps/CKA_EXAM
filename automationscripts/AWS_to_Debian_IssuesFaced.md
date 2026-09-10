# Generic issues faced for setting up on-prem Debian machine:

1. Passwordless authentication for user:
    - AWS used to stamp this line by default. Now its our responsibility to put it in at the end of sudoers file ( `sudo su; visudo` )  
    ```
    aditya ALL=(ALL) NOPASSWD: ALL
    ```
2. Update hostname on Debian machine after cloning VM:  
    1. `hostnamectl` : Check current hostname
    2. `sudo hostnamectl set-hostname <new_hostname>` : Set new hostname
    3. `sudo vi /etc/hosts` : Update loopback address to new hostname

3. Set static IP address for Private communication:  
    1. `sudo vi /etc/network/interfaces` : Update this `interfaces` file with static IP such as (assuming, `enp0s8` is your new Virtual Host-Only NAT Interface as seen in `ip a` command output):
    ```
    auto enp0s8
    iface enp0s8 inet static
        address 192.168.60.12
        netmask 255.255.255.0
    ``` 

4. Once you install ansible, you may still encounter issue like "Host unreachable" or "Failed to verify ssh" when trying to ping your own machine using `ansible -m ping all`:
    - Reason is, ansible relies on passwordless authentication of OpenSSH. 
    - OpenSSH requires fingerprint of the machine we are trying to access in the `$HOME/.ssh/known_hosts`
    - It might be possible to use `ssh-copy-id -i <key_File> <own_machine_hostname>`  

5. Basic utilities like `ipconfig / ip a / curl` are missing:
    - Debian is shipped as a trimmed-down version from traditional Ubuntu. 
    - So we need to ensure to install these packages ( `net-tools / curl` ), before continuing with Kubernetes setup. 

# Issues faced after moving to Debian and running automation scripts for Kubernetes installation (previously worked on AWS):

1. tigera-operator, kube-scheduler keeps going into CrashLoopBackOff 
- Initially, Debian VMs required to configure a Virtual Host-Only network interface to assign static private IPs to each VM (CP and worker / DP)
- When tigera-operator tries to make call to Calico service APIs, it is trying via the default interface (i.e. the NAT Network) instead of the new Host-Only network I defined

Debug approach:
- Firstly I checked if all ports required are open in the VM, using NMap.
- Secondly, I checked what is the Node IP used by kubelet and calico, using `kubelet get all -A -o wide` and `kubectl get nodes -o wide`


Soln:


2. kubectl commands like `kubectl get pods` is taking a long time to run or eventually timing out in between (occasionally)
- Main problem: 
    - Installed entire cluster on hard disk drive (HDD, D drive partition).

- Debug approach:
    - `kubectl logs -n kube-system -l component=etcd | grep -i "took too long"` this command gives the logs from `etcd` cluster DB for when the requests print "took too long" and threw a timeout

Soln:
- Short term solution, I increased timeout in `etcd` in its Static PodSpec YAML     
    ```
    sudo nano /etc/kubernetes/manifests/etcd.yaml
    ```     
- Meanwhile, long term solution proposed was, new SSD storage was provisioned with Debian VMs.