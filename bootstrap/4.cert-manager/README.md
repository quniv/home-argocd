# Cert-Manager

Automatic TLS certificate management using Let's Encrypt and Cloudflare DNS validation.

## Prerequisites

- Cluster must be running (see parent README.md)
- Cilium installed
- Cloudflare domain + API token

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
```

```bash
helm install cert-manager \
  jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

```bash
kubectl apply -f secrets.yml
kubectl apply -f clusterissuer.yml
```

```bash
kubectl apply -f certificate.yml
```
