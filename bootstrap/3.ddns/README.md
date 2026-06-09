# 3. DDNS

Cloudflare DDNS keeps `*.chillpickle.org` pointed at the current home IP.

> **GitOps managed** — after initial cluster bootstrap, this is handled by ArgoCD via
> `apps/cloudflare-ddns.yaml` (Helm chart `oci://ghcr.io/quniv/cloudflare-ddns`).
> The API token is pulled from Infisical at `/cloudflare-ddns/CLOUDFLARE_API_TOKEN`
> by the ExternalSecret in `manifests/cloudflare-ddns/externalsecret.yaml`.

## Bootstrap (one-time, before ArgoCD is live)

Seed the Cloudflare API token into Infisical under path `/cloudflare-ddns/CLOUDFLARE_API_TOKEN`,
then let ArgoCD reconcile the rest once ESO is running.

### Legacy manual deployment (pre-GitOps)

The files below are kept for reference only — do not apply them once ArgoCD manages the cluster:

```bash
kubectl create secret generic config-cloudflare-ddns \
  --from-file=config.json \
  -n cloudflare-ddns

kubectl apply -f deployment.yml
```
