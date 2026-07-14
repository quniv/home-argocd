# 4. Cert-Manager

Install cert-manager and provision the cluster's default wildcard TLS certificate
in the `cert-manager` namespace via Let's Encrypt and Cloudflare DNS-01.

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
kubectl apply -f certificate.yml   # default wildcard cert → cert-manager/tls-cert
```

The generated `tls-cert` Secret is the single source of truth. Its annotations
allow Reflector to create an automatic mirror named `tls-cert` in `infra`, where
the shared Gateway terminates TLS. To add a namespace-local copy for another
consumer, add that namespace to both Reflector namespace annotation values in
`certificate.yml`; do not copy the Secret manually or enable unrestricted
cluster-wide reflection.

Reflector is deployed by `apps/reflector.yaml`. During a fresh bootstrap, the
Gateway remains unready until ArgoCD installs Reflector and the `infra/tls-cert`
mirror appears.

After ArgoCD is installed, `apps/infra.yaml` continuously reconciles this same
bootstrap Certificate manifest as a narrowly included Git source.
