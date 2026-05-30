``` bash
kubectl create secret generic config-cloudflare-ddns --from-file=config.json -n cloudflare-ddns
kubectl apply -f deployment.yml
```