# 3. DDNS

Cloudflare DDNS keeps `*.chillpickle.org` pointed at the current home IP.

Fill in `config.json` with your Cloudflare API token and zone ID (see `.env` template in `bootstrap/`), then:

```bash
kubectl create secret generic config-cloudflare-ddns \
  --from-file=config.json \
  -n cloudflare-ddns

kubectl apply -f deployment.yml
```
