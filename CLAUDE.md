# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GitOps repo for the **lacia-cluster** (home Kubernetes cluster). Uses ArgoCD App of Apps pattern — all cluster state is declared here and synced by ArgoCD automatically.

## Architecture

```
apps/root.yaml          ← applied manually once; watches apps/ dir
  ├── apps/infrastructure.yaml  → manifests/infrastructure/  (sync-wave 1)
  └── apps/vvn-ce.yaml          → manifests/vvn-ce/          (sync-wave 2)
```

**Secrets flow:** Infisical → ESO `ClusterSecretStore` (`infisical`) → `ExternalSecret` CRDs → native k8s Secrets. The only manual secret is `infisical-auth` in `external-secrets` namespace (Infisical Machine Identity credentials).

**Cluster ingress:** Cilium Gateway API. A single `Gateway` named `external` in namespace `infra` terminates TLS (wildcard cert `*.chillpickle.org`). `HTTPRoute` resources in any namespace attach to it.

## Adding a new app

1. Create `apps/<name>.yaml` — ArgoCD `Application` pointing at `manifests/<name>/`
2. Create `manifests/<name>/` with k8s manifests
3. For secrets: add an `ExternalSecret` in `manifests/<name>/secrets/` referencing paths under `/<name>/` in Infisical
4. Set `annotations: argocd.argoproj.io/sync-wave: "2"` (or higher if it depends on infrastructure)

## HTTPRoute pattern

All apps expose via the existing Gateway — no per-app ingress controller needed:

```yaml
spec:
  parentRefs:
    - name: external
      namespace: infra
      sectionName: https
  hostnames:
    - "<app>.chillpickle.org"
```

## Bootstrap (one-time)

```bash
# 1. Install ESO
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --version 0.14.x

# 2. Seed the Infisical Machine Identity secret
kubectl create secret generic infisical-auth \
  --from-literal=clientId=<ID> \
  --from-literal=clientSecret=<SECRET> \
  -n external-secrets

# 3. Install ArgoCD
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  -n argocd --create-namespace --version 7.x \
  -f bootstrap/argocd-values.yaml

# 4. Hand control to ArgoCD
kubectl apply -f apps/root.yaml
```

## Common kubectl ops

```bash
# ArgoCD UI (before HTTPRoute is live)
kubectl -n argocd port-forward svc/argocd-server 8080:80

# Initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

# Trigger one-shot bulk crawl (vvn-ce)
kubectl create job -n vvn vdict-crawler-init --from=cronjob/vdict-crawler

# Force ArgoCD re-sync
kubectl -n argocd get app vvn-ce -o name | xargs kubectl -n argocd patch \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```
