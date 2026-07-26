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
		kubeadm join
		(provide the token & hash received during the 'kubeadm init' command)

## `kubeadm` requirements:

1. Open certain ports:
    - Refer Doc: https://kubernetes.io/docs/reference/networking/ports-and-protocols/

2. Swap memory should be disabled permanently on all nodes.
    - `kubelet`, by default, is designed to crash when trying to start on a node with swap memory enabled.
    - swap memory should either be tolerated by kubelet (using `failSwapOn:false`) or should be disabled permanently. 
    - Additionally, it comes down to a design choice to adhere to Kubernetes principles such as:  
        **1. Quality of Service (QoS) enforcement.**
        -   Kubernetes can prioritize pods under resources pressure.
        -   QoS tiers such as "Guaranteed", "Burstable", "BestEffort" -- which are assigned by Kubernetes based on memory and CPU limits.
        **2. Reliable Scheduling**
        -   Kubernetes assumes RAM is the only memory resource.
        -   If swap is enabled, it can overestimate memory. Resulting in overcommitting nodes and causing instability.
        **3. Performance isolation**
        -   In a multi-tenant cluster environment, one pod using swap memory can slow down others.
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
