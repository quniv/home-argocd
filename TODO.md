# TODO

- [x] Install Velero — backup cluster state to cloud storage (installed scaled-to-zero; psql data covered by Databasus → S3, see bootstrap/8.velero)
- [ ] Deploy vvn-ce project via ArgoCD
- [ ] Deploy daily-news project via ArgoCD
- [ ] Install monitoring stack (Prometheus + Grafana + Loki)
- [ ] Alertmanager setup (tied to monitoring stack)
- [ ] Security report — review findings from CI scanning (Trivy, Checkov, kube-linter)
- [ ] Install Infisical for self-hosted secret management
- [ ] Increase VM RAM via Vagrantfile if libvirt host has headroom
