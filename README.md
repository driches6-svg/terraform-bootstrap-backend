# Terraform Backend Bootstrap (S3 + DynamoDB + KMS)

This repo bootstraps a **remote Terraform backend** on AWS using:
- **S3** bucket (versioned, private, block-public-access)
- **KMS CMK** for server‑side encryption (SSE‑KMS) of objects
- **DynamoDB** lock table for **state locking**
- A **least‑privilege IAM role** and inline policy that grants just enough
  permissions for Terraform to read/write state and acquire the lock

> ⚠️ You **cannot** point Terraform's backend at resources that don't exist yet.
> Bootstrap these resources **first** using local state, then **migrate** to the
> remote backend.

---

## Structure

```
.
├── README.md
├── versions.tf
├── providers.tf
├── variables.tf
├── main.tf
├── iam.tf
├── outputs.tf
├── example-backend.hcl      # handy for `terraform init -backend-config=...`
└── .gitignore
```

---

## Quick start

1) **Authenticate** your AWS CLI/SDK (e.g., `aws sso login` or credentials).
2) (Optional) Create a dedicated AWS account/role for state.
3) **Init & apply (local state)**

```bash
terraform init
terraform apply -auto-approve
```

This will create:
- S3 bucket for state
- DynamoDB table for state locks
- KMS key for encryption
- IAM role & policy with least‑privilege access to the backend

4) **Migrate your Terraform projects to the remote backend**

Update your project's backend using either:

**Option A: `backend.hcl` file**

```bash
# Copy the values from outputs (or run: terraform output -json)
terraform init   -backend-config=example-backend.hcl   -migrate-state
```

**Option B: Inline flags**

```bash
terraform init   -backend-config="bucket=<from outputs>"   -backend-config="key=<path/to/your/stack.tfstate>"   -backend-config="region=<aws region>"   -backend-config="dynamodb_table=<from outputs>"   -backend-config="kms_key_id=<from outputs>"   -migrate-state
```

> The **`key`** is your own chosen path per stack/environment, e.g.:
> `platform/prod/network/terraform.tfstate`

5) **Use the IAM role**

If you're running Terraform from CI/CD, assume the created role (output `backend_role_arn`)
from your pipeline, or give your runner that role directly.

---

## Security & Ops defaults

- S3 **versioning** enabled
- S3 **SSE‑KMS** (CMK) with bucket default encryption
- S3 **block public access** (all 4 switches on)
- DynamoDB **PITR** and **SSE**
- IAM policy scoped to:
  - **ListBucket** with a **prefix condition** that limits visibility to your state prefix only
  - **Get/Put/Delete Object** on `s3://bucket/<prefix>/*`
  - DynamoDB **conditional writes** on the lock table
  - KMS **Encrypt/Decrypt/GenerateDataKey** on the specific CMK
- Opinionated tagging

---

## Inputs

| Variable | Description | Default |
|---------:|-------------|---------|
| `project` | Name/prefix for resources | `"tf-backend"` |
| `region` | AWS region | `"eu-west-1"` |
| `state_key_prefix` | S3 key prefix you want to restrict IAM to (e.g. `platform/`) | `"platform/"` |
| `principal_arns` | List of IAM principals allowed to assume backend role | `[]` |
| `kms_key_admin_arns` | Additional admins for the KMS CMK | `[]` |
| `tags` | Map of tags | `{}` |

---

## Outputs

- `state_bucket`
- `state_lock_table`
- `kms_key_id`
- `kms_key_arn`
- `backend_role_arn`
- `backend_policy_arn`

---

## .gitignore

State and sensitive local files are ignored by default.

---

## Notes

- Use **separate `key` prefixes** per environment/workspace to limit blast radius.
- Consider a **dedicated account** for shared services like state.
- Rotate the CMK per policy and monitor CloudTrail for access.
