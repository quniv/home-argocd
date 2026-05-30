# 2. Cilium

Install Cilium as the CNI. Replaces kube-proxy, enables Gateway API and L2 LoadBalancer announcements.

```bash
helm repo add cilium https://helm.cilium.io && helm repo update

helm install cilium cilium/cilium \
  --namespace kube-system \
  -f values.yaml

kubectl apply -f l2.yml
kubectl apply -f pools.yml
```

**L2 pool**: 192.168.1.235–192.168.1.254 announced on `eth1`.
