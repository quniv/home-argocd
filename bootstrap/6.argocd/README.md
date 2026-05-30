# 6. ArgoCD

Install ArgoCD and hand cluster control over to GitOps.

```bash
kubectl create namespace argocd

helm repo add argo https://argoproj.github.io/argo-helm && helm repo update

helm install argocd argo/argo-cd \
  --namespace argocd \
  -f values.yml
```

Apply the root app — ArgoCD takes over from here:

```bash
kubectl apply -f ../../apps/root.yaml
```

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```
