# CLAUDE.md

Cilium CNI config for lacia-cluster.

- `values.yaml` — Helm values: VXLAN tunnel, kube-proxy replacement, Gateway API, L2 announcements on eth1
- `l2.yml` — `CiliumL2AnnouncementPolicy` for eth1
- `pools.yml` — `CiliumLoadBalancerIPPool` 192.168.1.235–192.168.1.254

Upgrade: `helm upgrade cilium cilium/cilium --namespace kube-system -f values.yaml`
