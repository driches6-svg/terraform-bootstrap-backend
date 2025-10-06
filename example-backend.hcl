# Fill these in from `terraform output` after apply, and choose your own `key`.
bucket         = "<state_bucket>"
key            = "platform/prod/network/terraform.tfstate"
region         = "eu-west-1"
dynamodb_table = "<state_lock_table>"
kms_key_id     = "<kms_key_id>"
encrypt        = true
