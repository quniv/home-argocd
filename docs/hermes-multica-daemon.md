# Hermes Multica Daemon

Multica is installed and authenticated manually in the Hermes pod. GitOps only
defines a persistent workspace root on the `hermes-data` PVC:

```text
/opt/data/multica_workspaces
```

The Multica daemon must run as the `hermes` user (`UID:GID 10000:10000`). Running
it as root creates root-owned worktrees that the Hermes gateway cannot modify.

```mermaid
flowchart LR
    Operator[Manual Multica install and login]
    Daemon[Multica daemon UID 10000]
    Hermes[Hermes gateway UID 10000]
    Workspace[/opt/data/multica_workspaces]
    PVC[(hermes-data PVC)]

    Operator --> Daemon
    Daemon --> Workspace
    Hermes --> Workspace
    Workspace --> PVC
```

## Install and start

Install the Multica binary under `/opt/data/.local/bin`, which is already on the
image `PATH` and persists on the PVC. Do not install it under `/usr/local/bin`,
because that path is lost when Kubernetes replaces the pod.

Run installation, login, and daemon commands as the `hermes` user with a
persistent home:

```bash
POD="$(kubectl get pods -n hermes -l app=hermes \
  -o jsonpath='{.items[0].metadata.name}')"

kubectl exec -it -n hermes "$POD" -- sh
```

Inside the pod, switch to the Hermes identity:

```sh
su hermes -s /bin/sh
export HOME=/opt/data/home
export MULTICA_WORKSPACES_ROOT=/opt/data/multica_workspaces
mkdir -p "$HOME" "$MULTICA_WORKSPACES_ROOT" /opt/data/.local/bin
```

Install Multica into `/opt/data/.local/bin`, then authenticate and start it:

```sh
multica config set server_url https://api.multica.qtlab.dev
multica config set app_url https://multica.qtlab.dev
multica login
multica daemon start
multica daemon status
```

The GitOps-provided `MULTICA_WORKSPACES_ROOT` environment variable is inherited
by commands executed in the container. Export it explicitly as shown above when
using `su`, because `su` environment preservation differs between implementations.

## Verify ownership

```sh
id
stat -c '%A %a %u:%g %n' /opt/data/multica_workspaces
find /opt/data/multica_workspaces -maxdepth 3 \
  -printf '%M %u:%g %p\n' | head -n 50
```

The daemon, workspace root, and newly created task directories should report
UID/GID `10000:10000`. Retry or recreate tasks that reference the old
`/root/multica_workspaces` path; existing ACP sessions retain their original
absolute working directory.

## Pod replacement

The binary and Multica configuration persist under `/opt/data`, but the daemon
process does not. After Kubernetes replaces the Hermes pod, start the daemon
again manually as the `hermes` user.
