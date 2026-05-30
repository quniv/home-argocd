# Bootstrap

One-time setup steps to bring up the lacia-cluster from scratch. Run in order.

| Step | What it does |
|---|---|
| `1.cluster/` | Vagrant VMs + kubeadm cluster init |
| `2.cilium/` | Cilium CNI, L2 announcements, LoadBalancer IP pool |
| `3.ddns/` | Cloudflare DDNS to keep the home IP updated |
| `4.cert-manager/` | cert-manager + Let's Encrypt wildcard cert for `*.chillpickle.org` |
| `5.gatewayapi/` | `infra` namespace, Cilium Gateway `external`, TLS termination |
| `6.argocd/` | ArgoCD install + hand off to GitOps |

After step 6, install ESO and seed the Infisical secret:

```bash
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --version 0.14.x

kubectl create secret generic infisical-auth \
  --from-literal=clientId=<ID> \
  --from-literal=clientSecret=<SECRET> \
  -n external-secrets
```

Then apply the root ArgoCD app — it takes over from here:

```bash
kubectl apply -f ../apps/root.yaml
```
