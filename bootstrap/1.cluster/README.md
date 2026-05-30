# Vagrant

VM provisioning for the k8s-lab cluster. Creates 3 Ubuntu 22.04 VMs on libvirt.

## Prerequisites

```bash
# Install Vagrant
sudo dnf install vagrant

# Install libvirt plugin
vagrant plugin install vagrant-libvirt

# Ensure libvirt is running
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

# Add your user to libvirt group
sudo usermod -aG libvirt $USER
```

## Quick Start

### 1. Create and Boot VMs
```bash
cd 1.vagrant
vagrant up
```

This creates:
- cp-node: 192.168.121.10 (control plane, 4GB RAM, 2 CPUs)
- worker-1: 192.168.121.11 (worker, 4GB RAM, 2 CPUs)
- worker-2: 192.168.121.12 (worker, 4GB RAM, 2 CPUs)

### 2. SSH into a VM
```bash
vagrant ssh cp-node
# or
vagrant ssh worker-1
vagrant ssh worker-2
```

### 3. Install containerd
```bash
vagrant ssh cp-node # and worker-1, worker-2

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^.*$/# \/swapfile/' /etc/fstab

# Add required kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Set required sysctl params
sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params
sudo sysctl --system

# Add Docker apt repo
sudo apt update
sudo apt install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install containerd
sudo apt update
sudo apt install containerd.io

# Configure containerd to use systemd cgroup driver
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
exit
```
### 4. Install Kubernetes components
```bash
vagrant ssh cp-node # and worker-1, worker-2

# Add Kubernetes apt repo
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubelet, kubeadm, kubectl
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Restart kubelet
sudo systemctl daemon-reload
sudo systemctl restart kubelet
exit
```

### 5. Initialize Kubernetes cluster
```bash
vagrant ssh cp-node

sudo kubeadm init --pod-network-cidr=[IP_ADDRESS] --apiserver-advertise-address=[IP_ADDRESS] --config kubeadm-config.yml

# After init, set up kubectl for current user
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
exit
```
