locals {
  name = "${var.project}-${var.region}"
  tags = merge({
    Project = var.project
  }, var.tags)
}

# --- KMS CMK for S3 SSE-KMS ---
resource "aws_kms_key" "state" {
  description             = "CMK for Terraform state at-rest encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = local.tags
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.project}-state"
  target_key_id = aws_kms_key.state.key_id
}

# --- S3 bucket for state ---
resource "aws_s3_bucket" "state" {
  bucket        = "${local.name}-state"
  force_destroy = false
  tags          = local.tags
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Optional: lifecycle to retain noncurrent versions N days (tune as needed)
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "retain-noncurrent"
    status = "Enabled"
    noncurrent_version_expiration {
      noncurrent_days = 3650
    }
  }
}

# --- DynamoDB lock table ---
resource "aws_dynamodb_table" "locks" {
  name         = "${local.name}-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = local.tags
}
