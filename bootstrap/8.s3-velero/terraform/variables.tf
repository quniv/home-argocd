variable "bucket_name" {
  description = "S3 bucket name for Velero backups (globally unique)"
  type        = string
}

variable "region" {
  description = "AWS region where the bucket will be created"
  type        = string
  default     = "ap-southeast-1"
}

variable "iam_user_name" {
  description = "IAM username for the Velero service account"
  type        = string
  default     = "velero"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Project   = "lacia-cluster"
    Purpose   = "velero-backups"
  }
}
