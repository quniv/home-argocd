# home-argocd

GitOps repo for the **lacia-cluster** — a home Kubernetes cluster managed with ArgoCD App of Apps.

## Structure

```
apps/           ← ArgoCD Application manifests (watched by root.yaml)
manifests/      ← Kubernetes manifests synced by ArgoCD
bootstrap/      ← One-time cluster setup steps (numbered)
```

## Apps

| App | Namespace | Sync Wave |
|---|---|---|
| infrastructure | argocd, external-secrets, infra | 1 |
| vvn-ce | vvn | 2 |

## Quick links

- ArgoCD: `https://argocd.chillpickle.org`
- Bootstrap: see [`bootstrap/README.md`](bootstrap/README.md)
