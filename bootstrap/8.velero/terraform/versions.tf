terraform {
  required_version = ">= 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "terraform-rabbit2109"
    key    = "home-argocd/velero/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = var.region
}
