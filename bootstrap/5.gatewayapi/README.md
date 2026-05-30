# 5. Gateway API

Create the `infra` namespace and the shared Cilium `Gateway` that all apps attach to.

```bash
kubectl apply -f 1.infra.yaml   # infra namespace + Gateway "external" (TLS, *.chillpickle.org)
kubectl apply -f 2.demo.yml     # optional smoke-test HTTPRoute
```

After this step all apps can expose via `HTTPRoute` attaching to `gateway/external` in namespace `infra`.
