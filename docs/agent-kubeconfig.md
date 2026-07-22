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
4. Give it to this DevOps agent through its audited Multica environment store,
   not through an issue attachment, chat, email, or Git. On the same trusted
   workstation, create a mode-`0600` JSON envelope and set it as the agent's
   custom environment:

   ```bash
   umask 077
   base64 -w 0 ./agent-kubeconfig.yaml \
     | jq -R '{KUBECONFIG_B64: .}' > ./devops-agent-env.json
   multica agent env set 150a59dd-a8dd-4efa-ae72-33d80e92c246 \
     --custom-env-file ./devops-agent-env.json
   rm ./devops-agent-env.json ./agent-kubeconfig.yaml
   ```

   This is an owner/admin-only, audited operation. The agent receives the
   value as `KUBECONFIG_B64` and writes a mode-`0600` temporary kubeconfig only
   while a Kubernetes task is running. Rotate it by rerunning this process;
   replacing `custom_env` replaces the complete environment map, so preserve
   any future existing keys with the documented `"****"` placeholder.

## Revocation and elevation

Tokens expire automatically. To revoke all tokens immediately, delete the
ServiceAccount or remove its binding and let Argo CD reconcile. Do not add write
verbs, Secret access, `pods/exec`, or `pods/log` to this role. If a specific
operation needs more access, create a separate, narrowly scoped Role or
ClusterRole in a reviewed PR.
