output "state_bucket" {
  value       = aws_s3_bucket.state.id
  description = "S3 bucket name for Terraform state"
}

output "state_lock_table" {
  value       = aws_dynamodb_table.locks.name
  description = "DynamoDB table name for state locks"
}

output "kms_key_id" {
  value       = aws_kms_key.state.key_id
  description = "KMS Key ID for SSE-KMS"
}

output "kms_key_arn" {
  value       = aws_kms_key.state.arn
  description = "KMS Key ARN for SSE-KMS"
}

output "backend_role_arn" {
  value       = aws_iam_role.backend.arn
  description = "IAM role to assume when accessing the backend"
}

output "backend_policy_arn" {
  value       = aws_iam_policy.backend.arn
  description = "IAM policy ARN attached to the backend role"
}
