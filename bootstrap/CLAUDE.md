# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A Kubernetes learning lab environment provisioned with Vagrant + libvirt. The project sets up a 3-node Kubernetes cluster (1 control plane + 2 worker nodes) on local VMs for hands-on practice with Kubernetes concepts, networking, storage, and workload management.

## Environment & Tools

**Infrastructure Provider**: libvirt (Linux KVM/QEMU)
- Managed via Vagrant 2.2+
- Base image: generic/ubuntu2204 (Ubuntu 22.04 LTS)

**VMs**: All provisioned with basic K8s prerequisites (kernel modules, sysctl, swap disabled)
- `cp-node`: Control plane, 192.168.122.10, 4GB RAM, 2 CPUs
- `worker-1`: Worker node, 192.168.122.11, 4GB RAM, 2 CPUs
- `worker-2`: Worker node, 192.168.122.12, 4GB RAM, 2 CPUs

## Architecture

The Vagrant setup provisions three Ubuntu VMs on a private libvirt network (`192.168.122.0/24`) with:
1. **Base provisioning** (automated): Kernel module loading (overlay, br_netfilter), sysctl networking config, swap disabled, basic tools (curl, wget, git, vim)
2. **Manual installation** (post-provisioning): Docker, kubelet, kubeadm, kubectl must be installed manually inside each VM

The provision script is idempotent and exits early if issues occur (`set -e`).

## Common Commands

### Vagrant VM Management

```bash
# Bring up all VMs (creates and provisions them)
vagrant up

# Bring up a specific VM
vagrant up cp-node
vagrant up worker-1
vagrant up worker-2

# SSH into a VM
vagrant ssh cp-node
vagrant ssh worker-1

# Halt all VMs (shut down gracefully)
vagrant halt

# Destroy all VMs (irreversible)
vagrant destroy

# Check status
vagrant status

# Reload VMs (useful after Vagrantfile changes)
vagrant reload
```

### Post-VM Provisioning (Manual Steps Inside Each VM)

Once VMs are up, SSH into each and install Kubernetes components:

```bash
# Inside each VM (cp-node, worker-1, worker-2)

# Install Docker
apt-get update
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker vagrant

# Install Kubernetes tools
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# Start kubelet
systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet
```

### Initialize the Kubernetes Cluster

On the control plane (`cp-node`):

```bash
# Initialize the cluster
kubeadm init --apiserver-advertise-address=192.168.122.10 --pod-network-cidr=10.244.0.0/16

# Set up kubectl config for the vagrant user
mkdir -p /home/vagrant/.kube
cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Install a CNI plugin (e.g., Flannel for the 10.244.0.0/16 CIDR)
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

On each worker node:

```bash
# Join the cluster (use the token and discovery token CA hash from kubeadm init output)
kubeadm join 192.168.122.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

## Development Workflow

**Scenario**: Testing a new Kubernetes feature or workload

1. Ensure cluster is up and initialized: `vagrant status` and verify kubeadm/kubectl work
2. Apply manifests or test operators inside the cluster: `kubectl apply -f manifest.yaml`
3. Debug issues via SSH or kubectl logs/describe
4. Iterate and retest (no need to destroy VMs unless major changes)

**Scenario**: Modifying Vagrantfile (adding VMs, changing memory, etc.)

1. Edit `Vagrantfile`
2. Run `vagrant reload --provision` to apply changes to existing VMs
3. Run `vagrant up` to bring up new VMs defined in the file

## Key Configuration Details

- **Libvirt network**: `default` (192.168.122.0/24) – uses `libvirt__network_name` to bind VMs
- **Storage pool**: Default libvirt storage pool (`/var/lib/libvirt/images`)
- **CPU mode**: `host-passthrough` for nested virtualization support (useful for testing container runtimes)
- **DNS/DHCP**: Managed by libvirt default network

## Troubleshooting

### VM won't start
Check libvirt daemon: `sudo systemctl status libvirtd`
Ensure you have KVM/QEMU permissions: `sudo usermod -aG libvirt $USER`

### Vagrant can't connect to libvirt
Verify libvirt plugin: `vagrant plugin list | grep libvirt`
Install if missing: `vagrant plugin install vagrant-libvirt`

### Kubernetes API connectivity issues
Verify control plane is accessible from workers: `ssh worker-1` → `telnet 192.168.122.10 6443`
Check firewall: libvirt networks typically allow all internal traffic by default

### Swap not disabled after provisioning
Run manually inside VM: `swapoff -a` and `sed -i '/ swap / s/^/#/' /etc/fstab`

## Notes

- The Vagrantfile contains a minimal provision script; Docker and Kubernetes components are installed manually post-provisioning to allow for version control and custom configurations
- All VMs use `cpu_mode = "host-passthrough"` which requires a Linux host with KVM support
- For macOS/Windows, switch provider to `virtualbox` (requires adjusting Vagrantfile provider block)
