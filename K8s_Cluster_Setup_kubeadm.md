# Kubernetes cluster setup using `kubeadm`:

1. Setting up Control Plane
	- Run below command to initialize the control plane.
		kubeadm init
	- It returns a 'bootstrap token' and a SHA256 hash (of the cluster's Certificate Authority - CA)

2. Setting up the Cluster Network 
	- This needs to be setup using a Network Plugin such as Calico, Flannel etc.
	- This is required for IP-Per-Pod networking model (basically to achieve the objective of having an IP for each Pod)
	
3. Setting up Cluster Worker Nodes (or Secondary Control Nodes):
	- Run below command to join each secondary nodes (control / worker):  
		`kubeadm join`  
		(provide the token & hash received during the `kubeadm init` command)
    - If we don't capture the command from `kubeadm init` output, we can get the same join command by running below:  
    ```bash
    kubeadm token create --print-join-command
    ```

## `kubeadm` requirements:

1. Open certain ports:
    - Refer Doc: https://kubernetes.io/docs/reference/networking/ports-and-protocols/

2. Swap memory should be disabled permanently on all nodes.
    - `kubelet`, by default, is designed to crash when trying to start on a node with swap memory enabled.
    - swap memory should either be tolerated by kubelet (using `failSwapOn:false`) or should be disabled permanently. 
    - Additionally, doing this basically comes down to a design choice which adhere to Kubernetes principles such as:  
        **1. Quality of Service (QoS) enforcement.**  
        - QoS tiers such as "_Guaranteed_", "_Burstable_", "_BestEffort_" -- which are assigned by Kubernetes to Pods, based on memory and CPU limits.  
        - These tiers help Kubernetes prioritize pods under resource pressure.
        
        **2. Reliable Scheduling**  
        - Kubernetes assumes RAM is the only memory resource.
        - If swap is enabled, it can overestimate memory. Resulting in overcommitting nodes and causing instability.  
        
        **3. Performance isolation**
        - In a multi-tenant cluster environment, one pod using swap memory can slow down others.  
       
        **4. Fail-Fast Behaviour**
        -   Kubernetes expects pods to <u>fail</u> when resource limits are exceeded.
        -   This helps to trigger alerts, restarts, autoscaling faster. That is, take action on the issue early on instead of waiting.  
    - Refer post: https://medium.com/@mayankarya837/why-kubernetes-requires-swap-to-be-disabled-a-deep-dive-for-devops-engineers-87215564beff

    - Commands:

        ```bash
        sudo swapoff -a                        
        sudo sed -i '/ swap / s/^/#/' /etc/fstab  
        ```
        - First command disable swap temporarily
        - Second command disable swap permanently (persist across reboot)
        - If swap memory is disabled, the "Swap" row in `free -ght` will show all 0B.
3. Install a container runtime.  
    ### Context 
    #### Container Runtime
    - The software used to run a container.
    #### Container Runtime Interface (CRI)
    - In Kubernetes, CRI is the protocol for communication between `kubelet` and local container runtime. 
    - Any container runtime in the market must support CRI. 
        - This is why Docker Engine support was removed from the kubelet in v1.24
        - However, there is an opensource project called [cri-dockerd](https://mirantis.github.io/cri-dockerd/) which gives a way to control Docker based containers via Kubernetes CRI.
    - **We will choose `containerd` as the Container Runtime.**
    - To install `containerd`, follow below steps:
        1. Install `containerd` package:  
            - Download the appropriate package from their github release.  
            (packages are downloaded in non-root location)  
              I am picking the latest version as of July 2026. 
                ```bash
                wget https://github.com/containerd/containerd/releases/download/v2.3.3/containerd-2.3.3-linux-amd64.tar.gz
                ```   
            - Extract this package under `/usr/local`:  
                ```bash
                sudo su  
                cd /usr/local  
                tar -xvzf /home/ec2-user/containerd-2.3.3-linux-amd64.tar.gz
                ```
            - To ensure that `containerd` runs as a service on machine startup, add its bootup as system service: (right after following above steps)  
                ```bash
                mkdir -p /usr/local/lib/systemd/service/containerd.service
                cd /usr/local/lib/systemd/service/containerd.service
                wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
                
                ln -s /usr/local/lib/systemd/service/containerd.service/containerd.service /usr/lib/systemd/system/containerd.service

                systemctl daemon-reload
                systemctl enable --now containerd
                ```  
        2. Install `runc` package:
            - Download the appropriate package from their github release. (packages are downloaded in non-root location)  
                I am picking the latest version as of July 2026.   
                ```bash
                wget https://github.com/opencontainers/runc/releases/download/v1.5.1/runc.amd64
                ```   
            - Install it using:
                ```bash
                sudo su
                install -m 755 runc.amd64 /usr/local/sbin/runc
                ```
        3. Installing CNI plugins
            - Download the appropriate package from their github release. (packages are downloaded in non-root location)  
                I am picking the latest version as of July 2026.   
                ```bash
                wget https://github.com/containernetworking/plugins/releases/download/v1.9.1/cni-plugins-linux-amd64-v1.9.1.tgz
                ```   
            - Extract it under `/opt/cni/bin`:
                ```bash
                sudo su
                mkdir -p /opt/cni/bin
                cd /opt/cni/bin  
                tar -xvzf /home/ec2-user/cni-plugins-linux-amd64-v1.9.1.tgz
                ```
    - After installing all above binaries, create the `config.toml` file:
        ```bash
        sudo su
        mkdir -p /etc/containerd/
        containerd config default > /etc/containerd/config.toml
4. Install `kubeadm`, `kubelet` and `kubectl`:
    - Run `./install-kube-utils.sh` as normal user.


## Node setup:
### Objectives
1. Install a single control-plane Kubernetes cluster
2. Install a Pod network on the cluster so that your Pods can talk to each other

**Install a single control-plane, worker-node Kubernetes cluster**  

- We need to install the following tools on each of the nodes participating in the cluster.
    - `kubeadm`
        - The primary tool to initialize the control plane.
        - This tool sets up the required components of the control plane
            - coredns
                - Cluster's internal DNS Server.
                - This is how kubernetes is able to resolve all Services' DNS during internal pod communication.
            - etcd
            - kube-apiserver
            - kube-controller-manager
            - kube-scheduler
        - `kubeadm init` : Command used to initialize the control plane.
            - What does initialization do?
                1. Runs the preflight checks such as:
                    -   `swap` is off, ports free, ip_forward=1
                2. Generates the certificates / pki for API server, etcd etc. in `/etc/kubernetes/pki` directory
                3. Generates kubeconfig files (e.g. `admin.conf`, `kubelet.conf`)
                4. Starts etcd, kube-controller-manager, kube-apiserver, kube-scheduler
                5. Sets up RBAC, bootstraps token for `kubeadm join` command
                6. Deploy CoreDNS + kube-proxy on worker nodes (as a Deployment/DaemonSet, once CNI plugin is installed on each node)
        - `kubeadm join` : Command used to join worker nodes to the control node. Just kubelet + node registration.
            - What does the join command do?
                1. Runs preflight checks
                2. Contacts the API server (using the provided join token -> `--token` + CA cert hash -> `--discovery-token-ca-cert-hash`)
                3. Downloads the cluster info (CA cert, etc.) from control plane.
                4. Generates the worker node's own kubeconfig (in `$HOME/.kube/config` - config is the file not directory)
                5. Starts the `kubelet` service which will register _this_ worker node with the API Server. 
                    -  When we run `kubectl get nodes`, it will show the worker node as `NotReady` (until CNI plumbs it)
                
    - `kubelet`
        - This is a service attached to each node in the cluster
        - It helps in establishing communication with the kube-apiserver
    - `kubectl`   
        - This is a utility tool to get details about the cluster & containers running in it. 

**Initializing control-plane node**
- Check the commands and steps in :
    1. Run `install-kube-utils.sh`
    2. Run `control-plane_clust-init-private.sh`.

**Install a Pod network on the cluster so that your Pods can talk to each other**
- Setup the CNI Plugin (in our case, we are using 'Calico') on the worker node.
    - Follow steps in `worker-plane_clust-init-private.sh`
- Setup kubelet service to autostart.
    - Given in `install-kube-utils.sh` 

### Upgrading Kubernetes cluster:

As we have used `kubeadm` utility to setup our cluster - 
There are subcommands provided in `kubeadm` when Administrator decides to upgrade the Kubernetes version of cluster:
1. `kubeadm upgrade plan`
    - Checks the current version of Kubernetes against the latest available one in the repository.
    - It validates whether cluster is eligible for an upgrade. 
2. `kubeadm upgrade apply`
    - This is the primary command used to upgrade.
    - Upgrades the first control plane node of the cluster to specified version
3. `kubeadm upgrade diff`
    - Works like a preview, similar to `kubeadm upgrade apply --dry-run`.
    - It shows the configuration changes that would apply, without actually applying the changes on cluster.
4. `kubeadm upgrade node`
    - Updates the local kubelet configuration on the worker nodes or secondary control plane nodes.
    - It triggers necessary upgrade steps specific to that node.

#### Upgrade workflow:

Step 1.  
Update system software (e.g. `apt-get update`) & Kubernetes packages from your distribution or repository.  

Step 2.  
Check the current version of Kubernetes in your cluster

Step 3.  
Drain the control plane so that it evicts all running pods.

Step 4.  
Review the planned upgrade.

Step 5.  
Apply the upgrade on the primary control plane node.

Step 6.  
Uncordon the control plane node to resume pod scheduling.

Step 7.  
Repeat the above steps on all secondary control plane nodes & worker nodes, followed by a `kubelet` restart.


*BEST PRACTISE*
- Always upgrade one control plane node at a time, confirm stability and then proceed to upgrade other nodes.
