variable "project" {
  description = "Name/prefix for backend resources"
  type        = string
  default     = "tf-backend"
}

variable "region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "eu-west-1"
}

variable "tags" {
  description = "Common tags to apply"
  type        = map(string)
  default     = {}
}

variable "state_key_prefix" {
  description = "S3 key prefix to scope IAM permissions (e.g., 'platform/')"
  type        = string
  default     = "platform/"
}

variable "principal_arns" {
  description = "IAM principals allowed to assume the backend role (e.g., CI role, admins)"
  type        = list(string)
  default     = []
}

variable "kms_key_admin_arns" {
  description = "Additional IAM principals that can administer the CMK (full KMS access on this key)"
  type        = list(string)
  default     = []
}
