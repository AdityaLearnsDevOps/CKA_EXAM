Kubernetes cluster setup using `kubeadm`:

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

`kubeadm` requirements:

1. Open certain ports:
    - Refer Doc: https://kubernetes.io/docs/reference/networking/ports-and-protocols/

2. 