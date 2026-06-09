# 8. S3 — Velero Backup Bucket

Provisions the AWS infrastructure that Velero needs for cluster backups:

- S3 bucket (versioning + AES-256 SSE + public-access block)
- IAM user `velero` with a least-privilege policy scoped to that bucket
- IAM access key for the user

## Prerequisites

- AWS CLI configured (`aws configure`) or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` env vars set
- Terraform ≥ 1.5 installed (`tfswitch` is configured in this repo)

## Usage

```bash
cd bootstrap/8.s3-velero

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

### 2 — Update the ArgoCD application

In `apps/velero.yaml`, replace the placeholder bucket name:

```yaml
configuration:
  backupStorageLocation:
    - bucket: <VELERO_S3_BUCKET>   # ← replace with terraform output bucket_name
```

### 3 — (Optional) Opt-in Postgres volume backup

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
