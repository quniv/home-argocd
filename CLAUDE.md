# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

GitOps repo for the **lacia-cluster** (home Kubernetes cluster). Uses ArgoCD App of Apps pattern — all cluster state is declared here and synced by ArgoCD automatically. The GitHub remote (`https://github.com/quniv/home-argocd.git`) is what ArgoCD watches; pushing to `main` triggers reconciliation.

## Architecture

```
apps/root.yaml              ← applied manually once; watches apps/ dir
  ├── apps/eso.yml              → Bitnami external-secrets Helm chart  (no wave)
  ├── apps/infrastructure.yaml  → manifests/infrastructure/            (sync-wave 1)
  ├── apps/vvn-ce-infra.yaml    → manifests/vvn-ce/                   (sync-wave 2)
  ├── apps/vvn-ce-backend.yaml  → charts/webapp + values/vvn-ce.yaml  (sync-wave 2)
  ├── apps/vvn-ce-postgresql.yaml → Bitnami postgresql Helm chart     (sync-wave 2)
  └── apps/vvn-ce-redis.yaml    → Bitnami redis Helm chart            (sync-wave 2)
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

## charts/webapp — reusable Helm chart

`charts/webapp/` is a generic chart for stateless web services. It renders: Deployment, Service, and optionally HTTPRoute, ConfigMap, ExternalSecret, and a migration init container.

To deploy a new app with it, create `apps/<name>.yaml` pointing at `charts/webapp` and a per-app values file at `charts/webapp/values/<name>.yaml`. Key toggles in `values.yaml`:

| Key | Purpose |
|---|---|
| `migration.enabled` | Runs `alembic upgrade head` init container with retry loop |
| `httproute.enabled` | Attaches to Gateway `external` in namespace `infra` |
| `externalsecret.enabled` | Creates ESO `ExternalSecret` pulling from Infisical |
| `configmap.enabled` | Mounts a ConfigMap as env vars |

## Adding a new app

**Stateless webapp** (use the Helm chart):
1. Add `apps/<name>.yaml` — ArgoCD `Application` pointing at `charts/webapp` with `helm.valueFiles: [values/<name>.yaml]`
2. Add `charts/webapp/values/<name>.yaml` with your overrides
3. Set `sync-wave: "2"` annotation

**Raw manifests** (for infra or stateful workloads):
1. Add `apps/<name>.yaml` — ArgoCD `Application` pointing at `manifests/<name>/`
2. Create `manifests/<name>/` with k8s manifests
3. For secrets: add an `ExternalSecret` in `manifests/<name>/secrets/` referencing paths under `/<name>/` in Infisical
4. Set `sync-wave: "1"` (infra deps) or `"2"` (apps)

## HTTPRoute pattern

All apps attach to the existing Gateway — no per-app ingress controller:

```yaml
spec:
  parentRefs:
    - name: external
      namespace: infra
      sectionName: https
  hostnames:
    - "<app>.chillpickle.org"
```

## Local validation

```bash
# Activate git hooks (one-time, per clone)
bash .githooks/setup.sh

# YAML lint (same rules as CI)
yamllint -c .yamllint.yml manifests/ apps/

# Kubernetes schema validation
kubeconform \
  -ignore-missing-schemas \
  -kubernetes-version 1.28.0 \
  -schema-location default \
  -schema-location 'https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json' \
  manifests/ apps/
```

**CI on PRs**: yamllint auto-fixes style issues and commits back to the branch; kubeconform validates against k8s 1.28 schema. Security scanning (Trivy, Checkov, kube-linter) runs in parallel — findings are uploaded to the GitHub Security tab but are non-blocking.

**Git hooks**: `pre-commit` and `pre-push` run `gitleaks` to scan for secrets. Hard-blocks on any finding. False positives: add `# gitleaks:allow` inline or an allowlist entry to `.gitleaks.toml`. Requires `gitleaks` in PATH (`brew install gitleaks` or manual binary for Fedora).

## Bootstrap sequence (one-time, numbered dirs)

The `bootstrap/` directory maps to ordered steps:

```
1.cluster/    — Vagrant + kubeadm (3-node: cp-node 192.168.122.10, worker-1, worker-2)
2.cilium/     — Cilium CNI (helm install -f values.yaml), then apply l2.yml + pools.yml
3.ddns/       — Cloudflare DDNS deployment (reads bootstrap/.env for token + zone)
4.cert-manager/ — cert-manager helm + ClusterIssuer + wildcard Certificate
5.gatewayapi/ — infra namespace, Gateway `external`, demo HTTPRoute
6.argocd/     — ArgoCD helm install, then hand off with kubectl apply -f apps/root.yaml
7.infisical/  — seed infisical-auth secret; ESO can then pull from Infisical
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
kubectl -n argocd get app <app-name> -o name | xargs kubectl -n argocd patch \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```
