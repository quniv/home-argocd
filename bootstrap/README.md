# k8s-lab

A local Kubernetes learning lab environment. 3-node cluster (1 control plane + 2 workers) provisioned with Vagrant + libvirt on Linux.

## Quick Start

### 1. Provision VMs
```bash
cd vagrant
vagrant up
```

### 2. Initialize Kubernetes Cluster
```bash
vagrant ssh cp-node
sudo kubeadm init --config=/vagrant/kubeadm-config.yml
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown vagrant:vagrant ~/.kube/config
exit
```

### 3. Join Worker Nodes
Get token from kubeadm init output, then:
```bash
vagrant ssh worker-1
sudo kubeadm join 192.168.121.184:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
exit

vagrant ssh worker-2
sudo kubeadm join 192.168.121.184:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
exit
```

### 4. Install Cilium (CNI)
See [cilium/README.md](cilium/README.md)

### 5. Install Cloudflare DDNS
See [ddns/README.md](ddns/README.md)

### 6. Install Cert-Manager
See [cert-manager/README.md](cert-manager/README.md)

### 7. Install Infra/Gateway/Demo
See [infra/README.md](infra/README.md)

### 8. Install ArgoCD
See [argocd/README.md](argocd/README.md)
