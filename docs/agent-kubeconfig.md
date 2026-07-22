# Read-only agent kubeconfig

`manifests/infra/agent-kubeconfig-rbac.yaml` creates the `infra/agent-kubeconfig`
ServiceAccount and a cluster-wide **observer** role. It can read workload and
networking status. It cannot read Secrets, retrieve pod logs, use pod exec, or
modify any Kubernetes resource.

The repository never contains a bearer token or a kubeconfig. Kubernetes 1.24+
ServiceAccount tokens should be created through the TokenRequest API and expire;
this avoids revocable long-lived Secret tokens.

## Operator steps

1. Merge the PR and wait for the Argo CD `infra` application to become `Synced`
   and `Healthy`.
2. On an administrator workstation with the intended cluster context, run:

   ```bash
   git checkout <merged-revision>
   ./scripts/create-agent-kubeconfig.sh ./agent-kubeconfig.yaml
   ```

   The script creates a one-hour token by default and verifies that listing Pods
   is allowed while reading Secrets is denied. Set `TOKEN_DURATION=8h` only for
   a short, supervised session; the API server may impose a smaller maximum.
3. Verify locally:

   ```bash
   KUBECONFIG=./agent-kubeconfig.yaml kubectl get pods -A
   KUBECONFIG=./agent-kubeconfig.yaml kubectl auth can-i get secrets -A
   # Expected: no
   ```
4. Store the file only in an approved secret manager/runtime secret channel.
   Do **not** commit it, upload it to a Multica issue, paste it into chat, or
   email it. The receiving runtime should expose it as a file with mode `0600`
   and set `KUBECONFIG` to that path.

## Revocation and elevation

Tokens expire automatically. To revoke all tokens immediately, delete the
ServiceAccount or remove its binding and let Argo CD reconcile. Do not add write
verbs, Secret access, `pods/exec`, or `pods/log` to this role. If a specific
operation needs more access, create a separate, narrowly scoped Role or
ClusterRole in a reviewed PR.
