# 1. Cluster

Provision 3 Ubuntu 22.04 VMs with Vagrant + libvirt and initialize a kubeadm cluster.

## Prerequisites

```bash
sudo dnf install vagrant
vagrant plugin install vagrant-libvirt
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
```

## 1. Boot VMs

```bash
vagrant up
```

Creates: `cp-node` (192.168.122.10), `worker-1` (192.168.122.11), `worker-2` (192.168.122.12) — each 4 GB RAM, 2 CPUs.

## 2. Install containerd + kubeadm on each node

```bash
vagrant ssh cp-node   # repeat for worker-1, worker-2
```

Inside each VM:

```bash
# Swap off
sudo swapoff -a && sudo sed -i '/ swap / s/^.*$/# &/' /etc/fstab

# Kernel modules
sudo modprobe overlay br_netfilter
sudo tee /etc/sysctl.d/99-k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# containerd (via Docker repo)
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update && sudo apt-get install -y containerd.io
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo systemctl restart containerd

# kubeadm / kubelet / kubectl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

## 3. Init control plane

```bash
vagrant ssh cp-node
sudo kubeadm init --config /vagrant/kubeadm-config.yml
mkdir -p ~/.kube && sudo cp /etc/kubernetes/admin.conf ~/.kube/config && sudo chown $(id -u):$(id -g) ~/.kube/config
```

## 4. Join workers

Copy the `kubeadm join` command from the init output, then run it on each worker node.
