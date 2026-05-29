# home-argocd

GitOps repo for the **lacia-cluster** (home Kubernetes cluster). Uses ArgoCD with the App of Apps pattern.

## Cluster prerequisites

The cluster (`lacia-cluster`) is expected to already have:
- Cilium CNI with Gateway API enabled
- A `Gateway` named `external` in namespace `infra` (with `allowedRoutes.namespaces.from: All`)
- cert-manager with a wildcard cert for `*.chillpickle.org` stored as `wildcard-tls` in `infra`
- Cloudflare DDNS keeping the domain pointed at the cluster's public IP

See `devops/k8s-lab/` for provisioning those components.

---

## Bootstrap (run once)

### 1. Install External Secrets Operator

ESO must exist before ArgoCD can apply `ExternalSecret` CRDs.

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  --version 0.14.x
```

### 2. Create the Infisical Machine Identity secret

This is the only secret you ever create manually — ESO uses it to fetch everything else.

```bash
kubectl create secret generic infisical-auth \
  --from-literal=clientId=<MACHINE_IDENTITY_CLIENT_ID> \
  --from-literal=clientSecret=<MACHINE_IDENTITY_CLIENT_SECRET> \
  --namespace external-secrets
```

Get the credentials from: **Infisical → home-cluster project → Machine Identities**

### 3. Install ArgoCD

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  --version 7.x \
  -f bootstrap/argocd-values.yaml
```

### 4. Apply the root App of Apps

```bash
# Update the repoURL in apps/root.yaml if your repo URL differs
kubectl apply -f apps/root.yaml
```

ArgoCD now manages itself and syncs everything else automatically.

---

## Infisical secrets to populate

Before vvn-ce pods start, add these keys to **Infisical → home-cluster → prod**:

| Path | Description |
|---|---|
| `/vvn-ce/DATABASE_URL` | `postgresql+asyncpg://vocab:<password>@postgresql:5432/vocab` |
| `/vvn-ce/POSTGRES_PASSWORD` | The `<password>` used in DATABASE_URL |
| `/vvn-ce/OPENROUTER_API_KEY` | OpenRouter API key (`sk-or-v1-...`) |
| `/vvn-ce/CRAWLER_DB_URL` | Same as DATABASE_URL but uses the `postgresql+asyncpg` driver |

`DATABASE_URL` and `CRAWLER_DB_URL` point to the in-cluster PostgreSQL service (`postgresql.vvn.svc.cluster.local`). Use the same password for both and for `POSTGRES_PASSWORD`.

---

## Docker images to build & push

Images are not built by ArgoCD — build and push them to GHCR before syncing:

```bash
# Backend
cd vvn-ce/backend
docker build -t ghcr.io/quniv/vvn-ce-backend:latest .
docker push ghcr.io/quniv/vvn-ce-backend:latest

# Crawler
cd vvn-ce/crawler
docker build -t ghcr.io/quniv/vvn-ce-crawler:latest .
docker push ghcr.io/quniv/vvn-ce-crawler:latest
```

For GHCR to pull images in the cluster, create an image pull secret if the repo is private:

```bash
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=quniv \
  --docker-password=<GITHUB_PAT> \
  --namespace vvn
```

Then add `imagePullSecrets: [{name: ghcr-secret}]` to the backend Deployment and crawler CronJob pod specs.

---

## Initial bulk crawl

The CronJob runs every Sunday. For the first-time bulk crawl of ~80k words:

```bash
kubectl create job -n vvn vdict-crawler-init --from=cronjob/vdict-crawler
kubectl logs -n vvn -l job-name=vdict-crawler-init -f
```

---

## Accessing ArgoCD UI

Before the HTTPRoute is synced (initial bootstrap), use port-forward:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:80
# open http://localhost:8080
```

After ArgoCD syncs `manifests/infrastructure/argocd/httproute.yaml`, the UI is at `https://argocd.chillpickle.org`.

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

---

## Repo structure

```
home-argocd/
├── bootstrap/               # One-time manual install (ArgoCD Helm values)
├── apps/                    # ArgoCD Application definitions (App of Apps)
│   ├── root.yaml            # Watches this apps/ directory
│   ├── infrastructure.yaml  # → manifests/infrastructure/
│   └── vvn-ce.yaml          # → manifests/vvn-ce/
└── manifests/
    ├── infrastructure/
    │   ├── argocd/          # ArgoCD HTTPRoute (argocd.chillpickle.org)
    │   └── eso/             # ClusterSecretStore → Infisical
    └── vvn-ce/
        ├── namespace.yaml
        ├── configmap.yaml   # Non-secret env vars for the backend
        ├── secrets/         # ExternalSecret CRDs (no actual secret values)
        ├── backend/         # Deployment + Service + HTTPRoute
        ├── postgresql/      # StatefulSet + headless Service (5Gi PVC via volumeClaimTemplates)
        ├── redis/           # Deployment + Service + PVC
        └── crawler/         # CronJob (Sun 02:00 UTC)
```
