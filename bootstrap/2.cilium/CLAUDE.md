# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This directory contains Cilium Container Network Interface (CNI) configuration for the k8s-lab Kubernetes cluster. Cilium replaces kube-proxy with eBPF-based networking and provides advanced features like network policies, service mesh integration, and L2 announcements for load balancer IP exposure.

## File Structure

- **values.yaml**: Helm values for Cilium installation. Key settings:
  - `cluster.name`: lacia-cluster
  - `l2announcements.enabled`: true (enables L2 announcement for LoadBalancer IPs)
  - `routingMode: tunnel` with `tunnelProtocol: vxlan` (overlay networking)
  - `kubeProxyReplacement: true` (Cilium replaces kube-proxy)
  - `gatewayAPI.enabled`: true (for Kubernetes Gateway API support)
  - `ipv4NativeRoutingCIDR: 10.244.0.0/24` (pod CIDR from kubeadm-config.yml)

- **l2.yml**: CiliumL2AnnouncementPolicy for advertising external and LoadBalancer IPs on eth1 (L2 segment)

- **pools.yml**: CiliumLoadBalancerIPPool defining IP range (192.168.1.235-192.168.1.254) for automatic LoadBalancer IP assignment

## Common Commands

### Deployment

```bash
# Add Cilium Helm repo (if not already added)
helm repo add cilium https://helm.cilium.io
helm repo update

# Install or upgrade Cilium on the cluster
helm install cilium cilium/cilium \
  --namespace kube-system \
  -f values.yaml

# Or upgrade existing installation
helm upgrade cilium cilium/cilium \
  --namespace kube-system \
  -f values.yaml

# Apply L2 announcement and pool policies
kubectl apply -f l2.yml
kubectl apply -f pools.yml
```

### Verification & Debugging

```bash
# Check Cilium daemon status on each node
kubectl get pods -n kube-system -l k8s-app=cilium

# View Cilium agent logs
kubectl logs -n kube-system -l k8s-app=cilium --tail=100

# Check operator pod
kubectl get pods -n kube-system -l app.kubernetes.io/name=cilium-operator

# Verify L2 announcement policy
kubectl get ciliuml2announcementpolicies

# Verify load balancer IP pool
kubectl get ciliumloadbalancerippools

# View assigned LoadBalancer IPs
kubectl get svc -A -o wide | grep LoadBalancer

# Install cilium CLI for advanced debugging (optional)
# cilium status
# cilium connectivity test
```

## Network Architecture Notes

- **Pod CIDR**: 10.244.0.0/24 (from kubeadm-config.yml)
- **Service CIDR**: 10.96.0.0/16 (from kubeadm-config.yml)
- **L2 Interface**: eth1 (used for announcing IPs to the broader network)
- **LoadBalancer IP Range**: 192.168.1.235-192.168.1.254 (external network)
- **Networking Mode**: VXLAN tunnel overlay (supports multi-node pod communication)

## Integration with k8s-lab

This configuration is part of the k8s-lab vagrant-based 3-node cluster:
- Control plane: cp-node (192.168.121.184)
- Workers: worker-1, worker-2

After kubeadm cluster initialization and basic node setup (from k8s-lab/CLAUDE.md), Cilium is deployed as the CNI replacement. The L2 announcement and load balancer pool enable services to be accessible from the external network segment (192.168.1.0/24).

## Helm Chart Version

Uses the upstream Cilium Helm chart from https://helm.cilium.io. For production or specific version requirements, pin the chart version in helm install/upgrade commands (e.g., `--version 1.15.0`).
