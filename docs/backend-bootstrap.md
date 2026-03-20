# Backend Bootstrap

## Purpose

This repository includes an internal Terraform stack that bootstraps the S3 backend used by the Redis Cloud workflows.

Stack:

- [`stacks/state-backend`](/Users/alan/workspaces/alan-teodoro/frontline-education/stacks/state-backend)

The stack creates:

- one S3 bucket for Terraform remote state
- bucket versioning
- default server-side encryption
- S3 public access block
- bucket ownership controls
- a bucket policy that denies insecure transport
- an inline IAM policy on each GitHub Actions role that grants backend access

## Why this stack exists

The Redis Cloud apply and destroy workflows depend on:

- `TF_STATE_BUCKET`
- `TF_STATE_REGION`
- an IAM role that can read and write state objects in S3

Instead of creating those pieces manually, this stack lets the customer provision and standardize them with Terraform.

## Backend model

This stack is intentionally designed to run with the default local backend.

- It does not depend on the remote state bucket it is creating.
- It can be re-run even if the local state file is lost.
- If the bucket already exists, the stack skips bucket creation and reapplies the supporting S3 settings and IAM access policy.

## Usage

1. Copy [`terraform.tfvars.example`](/Users/alan/workspaces/alan-teodoro/frontline-education/stacks/state-backend/terraform.tfvars.example) to a local `terraform.tfvars`.
2. Set the bucket name, region, and GitHub Actions role ARNs.
3. Run:

```bash
cd stacks/state-backend
terraform init
terraform plan
terraform apply
```

## Important note for existing buckets

If the bucket already exists, this stack detects that condition and skips the bucket creation step. It then reapplies the supporting configuration to the existing bucket and refreshes the inline IAM policy on each GitHub Actions role.

This stack is intentionally separate from the GitHub Actions workflows. It is an internal bootstrap step that should be run before enabling the customer-facing automation.
