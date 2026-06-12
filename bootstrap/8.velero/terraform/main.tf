# ── S3 Bucket ──────────────────────────────────────────────────────────────────

resource "aws_s3_bucket" "velero" {
  bucket = var.bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "velero" {
  bucket = aws_s3_bucket.velero.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "velero" {
  bucket = aws_s3_bucket.velero.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Object retention is managed by the consumers themselves (Velero backup TTLs,
# Databasus retention policies) — no expiration rule here, only multipart hygiene
resource "aws_s3_bucket_lifecycle_configuration" "velero" {
  bucket = aws_s3_bucket.velero.id

  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 3
    }
  }
}

resource "aws_s3_bucket_public_access_block" "velero" {
  bucket                  = aws_s3_bucket.velero.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── IAM Policy ─────────────────────────────────────────────────────────────────

data "aws_iam_policy_document" "velero" {
  statement {
    sid = "VeleroBucketAccess"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
  }

  statement {
    sid = "VeleroObjectAccess"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts",
    ]
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]
  }
}

resource "aws_iam_policy" "velero" {
  name        = "velero-${var.bucket_name}"
  description = "Velero backup permissions for s3://${var.bucket_name}"
  policy      = data.aws_iam_policy_document.velero.json
  tags        = var.tags
}

# ── IAM User + Access Key ───────────────────────────────────────────────────────

resource "aws_iam_user" "velero" {
  name = var.iam_user_name
  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "velero" {
  user       = aws_iam_user.velero.name
  policy_arn = aws_iam_policy.velero.arn
}

resource "aws_iam_access_key" "velero" {
  user = aws_iam_user.velero.name
}
