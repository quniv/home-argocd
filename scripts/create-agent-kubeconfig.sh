#!/usr/bin/env bash
# Generate a short-lived, read-only ServiceAccount kubeconfig outside Git.
# Run this only after Argo CD has applied manifests/infra/agent-kubeconfig-rbac.yaml.
set -euo pipefail

namespace="${NAMESPACE:-infra}"
service_account="${SERVICE_ACCOUNT:-agent-kubeconfig}"
duration="${TOKEN_DURATION:-1h}"
output="${1:-./agent-kubeconfig.yaml}"

if [ -e "$output" ]; then
  echo "Refusing to overwrite existing file: $output" >&2
  exit 1
fi

server="$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')"
ca_data="$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')"

if [ -z "$server" ] || [ -z "$ca_data" ]; then
  echo "Current kubectl context must provide a server URL and CA data." >&2
  exit 1
fi

token="$(kubectl -n "$namespace" create token "$service_account" --duration="$duration")"
umask 077
kubectl --kubeconfig="$output" config set-cluster agent-cluster \
  --server="$server" \
  --certificate-authority-data="$ca_data" \
  --embed-certs=true >/dev/null
kubectl --kubeconfig="$output" config set-credentials "$service_account" --token="$token" >/dev/null
kubectl --kubeconfig="$output" config set-context agent-observer \
  --cluster=agent-cluster \
  --user="$service_account" \
  --namespace="$namespace" >/dev/null
kubectl --kubeconfig="$output" config use-context agent-observer >/dev/null
chmod 600 "$output"

KUBECONFIG="$output" kubectl auth can-i list pods --all-namespaces
KUBECONFIG="$output" kubectl auth can-i get secrets --all-namespaces
echo "Created $output (mode 0600; expires after $duration or the cluster maximum)."
echo "Do not commit, attach to an issue, paste into chat, or send through email."
