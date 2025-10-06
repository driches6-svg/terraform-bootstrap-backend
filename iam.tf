# IAM role that Terraform (or CI) will assume to access the backend
resource "aws_iam_role" "backend" {
  name               = "${local.name}-backend-role"
  assume_role_policy = data.aws_iam_policy_document.backend_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "backend_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.principal_arns
    }
  }
}

# Policy granting least-privilege access to the state bucket/prefix, lock table, and KMS CMK
data "aws_iam_policy_document" "backend" {
  statement {
    sid       = "S3ListWithPrefix"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.state.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [var.state_key_prefix, "${var.state_key_prefix}*"]
    }
  }

  statement {
    sid = "S3ObjectCRUDOnPrefix"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.state.arn}/${var.state_key_prefix}*"]
  }

  statement {
    sid = "DynamoDBStateLocking"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:ConditionCheckItem"
    ]
    resources = [aws_dynamodb_table.locks.arn]
  }

  statement {
    sid = "UseKMSForS3"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.state.arn]
  }
}

resource "aws_iam_policy" "backend" {
  name   = "${local.name}-backend-policy"
  policy = data.aws_iam_policy_document.backend.json
}

resource "aws_iam_role_policy_attachment" "backend_attach" {
  role       = aws_iam_role.backend.name
  policy_arn = aws_iam_policy.backend.arn
}

# KMS key policy allowing account root and optional extra admins
data "aws_caller_identity" "current" {}

resource "aws_kms_key_policy" "state" {
  key_id = aws_kms_key.state.key_id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = concat(
      [
        {
          "Sid" : "AllowAccountRoot",
          "Effect" : "Allow",
          "Principal" : { "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" },
          "Action" : "kms:*",
          "Resource" : "*"
        }
      ],
      length(var.kms_key_admin_arns) > 0 ? [
        {
          "Sid" : "KeyAdmins",
          "Effect" : "Allow",
          "Principal" : { "AWS" : var.kms_key_admin_arns },
          "Action" : "kms:*",
          "Resource" : "*"
        }
      ] : []
    )
  })
}
