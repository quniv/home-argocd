# CLAUDE.md

Bootstrap directory for the lacia-cluster. Each numbered subdirectory is a one-time setup step; run them in order.

## Cluster facts

- **Nodes**: cp-node (192.168.122.10), worker-1 (192.168.122.11), worker-2 (192.168.122.12)
- **Provider**: libvirt / KVM via Vagrant
- **OS**: Ubuntu 22.04
- **CNI**: Cilium (VXLAN, kube-proxy replacement, Gateway API)
- **Pod CIDR**: 10.244.0.0/16 | **Service CIDR**: 10.96.0.0/16
- **LoadBalancer pool**: 192.168.1.235–192.168.1.254 (L2 on eth1)
- **Domain**: `*.chillpickle.org` (wildcard cert, Cloudflare DNS)

## Sensitive files

- `bootstrap/.env` — Cloudflare token + zone; gitignored, never commit
- `bootstrap/3.ddns/config.json` — tokens replaced with placeholders in repo

After all steps, ArgoCD manages the cluster via `apps/root.yaml`. Don't apply manifests manually after that point.
