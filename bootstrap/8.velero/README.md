# 8. Velero — Backup Infrastructure

Provisions the AWS infrastructure for cluster backups:

- S3 bucket (versioning + AES-256 SSE + public-access block)
- IAM user `velero` with a least-privilege policy scoped to that bucket
- IAM access key for the user
- Lifecycle rule aborting incomplete multipart uploads after 3 days

The bucket is shared by two consumers:

| Consumer | Configured via | Retention |
|---|---|---|
| Velero (`apps/velero.yaml`) | Helm values + Infisical | Velero backup TTLs |
| Databasus (`apps/databasus.yaml`) | UI (S3 storage destination) | Databasus retention policies |

> **Note:** Velero is currently **parked at zero replicas** to save cluster
> resources — Databasus is the active backup mechanism for psql. See
> "Scale-to-zero" below.

## Prerequisites

- AWS CLI configured (`aws configure`) or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars set
- Terraform ≥ 1.5 installed (`tfswitch` is configured in this repo)

## Usage

```bash
cd bootstrap/8.velero/terraform

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set your bucket name (must be globally unique)

terraform init
terraform plan
terraform apply
```

## After apply

`terraform output` prints three values. Use them to complete the Velero setup:

### 1 — Seed credentials into Infisical

Go to the **home-cluster** project → **prod** environment and add:

| Infisical path | Value |
|---|---|
| `/velero/AWS_ACCESS_KEY_ID` | `terraform output aws_access_key_id` |
| `/velero/AWS_SECRET_ACCESS_KEY` | `terraform output -raw aws_secret_access_key` |

These feed the `velero-creds` secret (velero namespace). Databasus takes
the same credentials directly through its UI when adding the S3 storage
destination (`terraform output bucket_name`, region `ap-southeast-1`).

### 2 — Update the ArgoCD application

In `apps/velero.yaml`, replace the placeholder bucket name:

```yaml
configuration:
  backupStorageLocation:
    - bucket: <VELERO_S3_BUCKET>   # ← replace with terraform output bucket_name
```

### 3 — Scale Velero to zero (current operating mode)

The Helm chart hardcodes `replicas: 1`, so after the first ArgoCD sync run:

```bash
kubectl -n velero scale deploy/velero --replicas=0
```

`ignoreDifferences` on `/spec/replicas` in `apps/velero.yaml` keeps ArgoCD
selfHeal from scaling it back up. To reactivate Velero later:

```bash
kubectl -n velero scale deploy/velero --replicas=1
```

(and consider re-enabling `deployNodeAgent: true` for volume backups).

### 4 — (Optional) Opt-in Postgres volume backup

Add the annotation to your Postgres pod template in `manifests/psql/` so Velero
includes the PVC data in backups:

```yaml
metadata:
  annotations:
    backup.velero.io/backup-volumes: data   # replace 'data' with the actual volume name
```

## State file warning

`terraform.tfstate` holds the IAM secret key in plaintext — it is gitignored.
Keep it safe or configure a remote backend (S3 + DynamoDB lock) before running
in a shared environment.
