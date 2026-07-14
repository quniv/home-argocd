# Hermes Multica Daemon

The Hermes pod runs the Multica daemon as the same `hermes` identity used by
the Hermes gateway (`UID:GID 10000:10000`). Both processes share the
`hermes-data` PVC, so Multica workspaces remain writable and survive pod
replacement.

```mermaid
flowchart LR
    ESO[External Secrets Operator] -->|MULTICA_TOKEN| Secret[multica-daemon-creds]
    Init[install-multica init container] -->|verified v0.4.0 binary| Bin[emptyDir: multica-bin]
    Secret --> Daemon[Multica daemon UID 10000]
    Bin --> Daemon
    Daemon --> Workspace[/opt/data/multica_workspaces]
    Hermes[Hermes gateway UID 10000] --> Workspace
    Workspace --> PVC[(hermes-data PVC)]
```

## Prerequisite

Create a Multica personal access token, then store it in Infisical at:

```text
/hermes/MULTICA_TOKEN
```

Use a `mul_...` user PAT or an `mcn_...` Cloud Node PAT. Never commit the token
to this repository. ESO publishes it as the `multica-daemon-creds` Kubernetes
Secret in the `hermes` namespace.

## Runtime layout

- Multica version: `0.4.0`, pinned by release URL and SHA-256 checksum.
- Multica home: `/opt/data/home`.
- Workspace root: `/opt/data/multica_workspaces`.
- Process identity: `10000:10000`.
- Automatic CLI updates: disabled; update the pinned version and checksum in
  `manifests/hermes/deployment.yaml` through Git review.

The installer downloads the official Linux AMD64 release archive during pod
initialization. The pod therefore needs outbound HTTPS access to GitHub
releases whenever it is created.

## Rollout verification

After ArgoCD syncs the application, verify ESO and the pod:

```bash
kubectl get externalsecret -n hermes multica-daemon-creds
kubectl get secret -n hermes multica-daemon-creds
kubectl rollout status -n hermes deployment/hermes
kubectl get pods -n hermes -l app=hermes
```

Inspect the installer and daemon without printing the Secret:

```bash
POD="$(kubectl get pods -n hermes -l app=hermes \
  -o jsonpath='{.items[0].metadata.name}')"

kubectl logs -n hermes "$POD" -c install-multica
kubectl logs -n hermes "$POD" -c multica-daemon
kubectl exec -n hermes "$POD" -c multica-daemon -- id
kubectl exec -n hermes "$POD" -c multica-daemon -- \
  multica daemon status
kubectl exec -n hermes "$POD" -c multica-daemon -- \
  stat -c '%A %a %u:%g %n' /opt/data/multica_workspaces
```

The daemon and workspace should both report UID/GID `10000:10000`. Retry or
recreate tasks that reference the old `/root/multica_workspaces` path; existing
ACP sessions retain their original absolute working directory.

## Rollback

Revert the Deployment and ExternalSecret changes, then sync the Hermes ArgoCD
application. Removing the sidecar stops the GitOps-managed daemon but leaves
its configuration and workspaces on the PVC under `/opt/data`.
