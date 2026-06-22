# ── GitHub Actions OIDC ────────────────────────────────────────────────────────
# Allows the home-argocd repo's Terraform CI workflow to assume an AWS role
# without storing long-lived credentials anywhere.

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

data "aws_iam_policy_document" "tf_ci_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      # Allow any branch/PR on the repo — tighten to a specific branch if needed
      values = ["repo:quniv/home-argocd:*"]
    }
  }
}

resource "aws_iam_role" "tf_ci" {
  name               = "home-argocd-tf-ci"
  assume_role_policy = data.aws_iam_policy_document.tf_ci_trust.json
  tags               = var.tags
}

# Permissions: read S3 state + manage the Velero bucket/IAM resources declared
# in main.tf so that `terraform plan` can describe live state.
data "aws_iam_policy_document" "tf_ci" {
  # Read/write the Terraform state file in S3
  statement {
    sid     = "TerraformStateAccess"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [
      "arn:aws:s3:::terraform-rabbit2109/home-argocd/velero/terraform.tfstate"
    ]
  }
  statement {
    sid       = "TerraformStateBucket"
    actions   = ["s3:ListBucket", "s3:GetBucketLocation"]
    resources = ["arn:aws:s3:::terraform-rabbit2109"]
  }

  # Read S3 resources managed by main.tf (for plan)
  statement {
    sid = "S3ReadManaged"
    actions = [
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetLifecycleConfiguration",
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]
    resources = ["arn:aws:s3:::${var.bucket_name}"]
  }

  # Read IAM resources managed by main.tf (for plan)
  statement {
    sid = "IAMReadManaged"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:GetUser",
      "iam:ListAttachedUserPolicies",
      "iam:ListAccessKeys",
      "iam:GetOpenIDConnectProvider",
      "iam:GetRole",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tf_ci" {
  name        = "home-argocd-tf-ci"
  description = "Least-privilege policy for GitHub Actions Terraform CI"
  policy      = data.aws_iam_policy_document.tf_ci.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "tf_ci" {
  role       = aws_iam_role.tf_ci.name
  policy_arn = aws_iam_policy.tf_ci.arn
}
