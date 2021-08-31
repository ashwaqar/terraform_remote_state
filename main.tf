provider "aws" {
  region = "us-west-2"
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    purpose   = "terraform state for EKS"
    owner     = "Prasanth Salla"
    terraform = "true"
  }
}

locals {
  account_id = data.aws_iam_account_alias.current.account_alias
}

data "aws_iam_account_alias" "current" {}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-aws-gh-screening-eks-state-${local.account_id}-${var.env}"

  # Enable versioning so we can see the 
  # full revision history of our state files
  versioning {
    enabled = true
  }

  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  force_destroy = true

  lifecycle {
    #variable expansion is not allowed inside this block
    prevent_destroy = true
  }

  tags = local.common_tags
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-aws-gh-screening-eks-locks-${local.account_id}-${var.env}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.common_tags
}