# 4. Cert-Manager

Install cert-manager and provision a wildcard TLS cert for `*.chillpickle.org` via Let's Encrypt + Cloudflare DNS-01.

```bash
helm repo add jetstack https://charts.jetstack.io && helm repo update

helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  --set installCRDs=true
```

Then apply in order:

```bash
kubectl apply -f secrets.yml       # Cloudflare API token secret
kubectl apply -f clusterissuer.yml # Let's Encrypt ClusterIssuer (DNS-01)
kubectl apply -f certificate.yml   # wildcard cert *.chillpickle.org → secret in infra ns
```
