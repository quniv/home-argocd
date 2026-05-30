# Cilium

Container Network Interface (CNI) for the k8s-lab cluster. Provides eBPF-based networking, load balancer IP management, and L2 announcements.

## Installation
> install after kubeadm init
```bash
helm repo add cilium https://helm.cilium.io
helm repo update
```
```bash
helm install cilium cilium/cilium \
  --namespace kube-system \
  -f values.yaml
```

```bash
kubectl apply -f l2.yml
kubectl apply -f pools.yml
```