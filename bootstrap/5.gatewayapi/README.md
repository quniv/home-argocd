# 5. Gateway API

Create the `infra` namespace and the shared Cilium `Gateway` that all apps attach
to. The Gateway consumes `infra/tls-cert`, which Reflector mirrors from the
source Secret in `cert-manager`.

```bash
kubectl apply -f 1.infra.yaml   # infra namespace + Gateway "external"
kubectl apply -f 2.demo.yml     # optional smoke-test HTTPRoute
```

After Reflector creates `infra/tls-cert`, all apps can expose via `HTTPRoute`
attaching to `gateway/external` in namespace `infra`.

After ArgoCD is installed, `apps/infra.yaml` continuously reconciles this same
bootstrap Gateway manifest as a narrowly included Git source.
