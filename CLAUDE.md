# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GitOps repo for the **lacia-cluster** (home Kubernetes cluster). Uses ArgoCD App of Apps pattern — all cluster state is declared here and synced by ArgoCD automatically. The GitHub remote (`https://github.com/quniv/home-argocd.git`) is what ArgoCD watches; pushing to `main` triggers reconciliation.

## Architecture

```
apps/root.yaml          ← applied manually once; watches apps/ dir
  ├── apps/infrastructure.yaml  → manifests/infrastructure/  (sync-wave 1)
  └── apps/vvn-ce.yaml          → manifests/vvn-ce/          (sync-wave 2)
```

**Secrets flow:** Infisical → ESO `ClusterSecretStore` (`infisical`, project `home-cluster`, env `prod`) → `ExternalSecret` CRDs → native k8s Secrets. The only manual secret is `infisical-auth` in `external-secrets` namespace (Infisical Machine Identity credentials).

**Cluster ingress:** Cilium Gateway API. A single `Gateway` named `external` in namespace `infra` terminates TLS (wildcard cert `*.chillpickle.org`). `HTTPRoute` resources in any namespace attach to it.

## Namespace layout

| Namespace | Purpose |
|---|---|
| `argocd` | ArgoCD itself |
| `external-secrets` | ESO operator + `infisical-auth` secret |
| `infra` | Gateway `external`, wildcard TLS cert |
| `vvn` | vvn-ce app (backend, postgres, redis, crawler) |

## Cluster network

- **Pod CIDR**: 10.244.0.0/16 | **Service CIDR**: 10.96.0.0/16
- **LoadBalancer IP pool**: 192.168.1.235–192.168.1.254 (Cilium L2 announcements on eth1)
- CNI: Cilium with VXLAN tunnel, kube-proxy replacement, Gateway API enabled

## vvn-ce stack (`manifests/vvn-ce/`)

| Component | Kind | Image |
|---|---|---|
| Backend (FastAPI) | Deployment | `ghcr.io/qitpydev/vvn-ce-backend:latest` |
| PostgreSQL 16 | StatefulSet | `postgres:16-alpine` (5 Gi PVC, db/user: `vocab`) |
| Redis | Deployment | — |
| Crawler | CronJob | `ghcr.io/qitpydev/vvn-ce-crawler:latest` |

The backend Deployment uses an init container (`alembic upgrade head`) to run migrations before the API starts. The crawler runs weekly (Sunday 02:00 UTC); trigger a one-shot run manually when needed.

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

## Bootstrap sequence (one-time, numbered dirs)

The `bootstrap/` directory maps to ordered steps:

```
1.cluster/    — Vagrant + kubeadm (3-node: cp-node 192.168.122.10, worker-1, worker-2)
2.cilium/     — Cilium CNI (helm install -f values.yaml), then apply l2.yml + pools.yml
3.ddns/       — Cloudflare DDNS deployment (reads bootstrap/.env for token + zone)
4.cert-manager/ — cert-manager helm + ClusterIssuer + wildcard Certificate
5.gatewayapi/ — infra namespace, Gateway `external`, demo HTTPRoute
6.argocd/     — ArgoCD helm install, then hand off with kubectl apply -f apps/root.yaml
```

After step 6, ESO must be installed and `infisical-auth` seeded before apps can pull secrets:

```bash
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets --create-namespace --version 0.14.x

kubectl create secret generic infisical-auth \
  --from-literal=clientId=<ID> \
  --from-literal=clientSecret=<SECRET> \
  -n external-secrets
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
