``` bash
k create ns argocd

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

helm install argocd argo/argo-cd \
     --namespace argocd

k apply -f ./apps/root.yml
```

