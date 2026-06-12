output "bucket_name" {
  description = "S3 bucket name — update <VELERO_S3_BUCKET> in apps/velero.yaml with this value"
  value       = aws_s3_bucket.velero.id
}

output "bucket_region" {
  description = "S3 region — confirm it matches configuration.backupStorageLocation[0].config.region in apps/velero.yaml"
  value       = var.region
}

output "aws_access_key_id" {
  description = "Store in Infisical at path /velero/AWS_ACCESS_KEY_ID (home-cluster project, prod env)"
  value       = aws_iam_access_key.velero.id
}

output "aws_secret_access_key" {
  description = "Store in Infisical at path /velero/AWS_SECRET_ACCESS_KEY (home-cluster project, prod env)"
  value       = aws_iam_access_key.velero.secret
  sensitive   = true
}
