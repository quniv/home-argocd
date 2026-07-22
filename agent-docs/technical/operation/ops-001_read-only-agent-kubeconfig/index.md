# Create a read-only agent kubeconfig

- Code: ops-001
- Description: Create and hand off a short-lived, read-only agent kubeconfig.
- Status: in progress

`manifests/infra/agent-kubeconfig-rbac.yaml` creates the `infra/agent-kubeconfig` ServiceAccount and a cluster-wide observer role. It can read workload and networking status. It cannot read Secrets, retrieve pod logs, use pod exec, or modify Kubernetes resources.

The repository never contains a bearer token or kubeconfig. Kubernetes 1.24+ ServiceAccount tokens are created through the TokenRequest API and expire automatically.

## Prerequisites

- The reviewed RBAC manifest is merged.
- Argo CD has reconciled the `infra` application to `Synced` and `Healthy`.
- You have an administrator workstation using the intended cluster context.

## Generate and verify the kubeconfig

1. Check out the merged revision and generate a one-hour kubeconfig.

   ```bash
   git checkout <merged-revision>
   ./scripts/create-agent-kubeconfig.sh ./agent-kubeconfig.yaml
   ```

   Set `TOKEN_DURATION=8h` only for a short, supervised session. The API server can impose a lower maximum.

2. Verify that workload reads work and Secret reads are denied.

   ```bash
   KUBECONFIG=./agent-kubeconfig.yaml kubectl get pods -A
   KUBECONFIG=./agent-kubeconfig.yaml kubectl auth can-i get secrets -A
   # Expected: no
   ```

## Hand off the kubeconfig

Use the audited Multica environment store, not an issue attachment, chat, email, or Git. On the trusted administrator workstation, create a mode-`0600` envelope and set it on the DevOps agent.

```bash
umask 077
base64 -w 0 ./agent-kubeconfig.yaml \
  | jq -R '{KUBECONFIG_B64: .}' > ./devops-agent-env.json
multica agent env set 150a59dd-a8dd-4efa-ae72-33d80e92c246 \
  --custom-env-file ./devops-agent-env.json
rm ./devops-agent-env.json ./agent-kubeconfig.yaml
```

This is an owner/admin-only audited operation. The agent receives `KUBECONFIG_B64` and writes a mode-`0600` temporary kubeconfig only while a Kubernetes task runs. Replacing `custom_env` replaces the full environment map; preserve future existing keys with the documented `"****"` placeholder.

## Revoke or elevate access

Tokens expire automatically. To revoke all active tokens immediately, delete the ServiceAccount or remove its binding and let Argo CD reconcile. Do not add write verbs, Secret access, `pods/exec`, or `pods/log` to this role. For a specific additional requirement, create a separate, narrowly scoped Role or ClusterRole in a reviewed PR.
