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
- optionally, one GitHub Actions OIDC IAM role per workflow environment

## Why this stack exists

The Redis Cloud apply and destroy workflows depend on:

- `TF_STATE_BUCKET` and `TF_STATE_REGION`, or
- environment-specific backend secrets such as `TF_STATE_BUCKET_DEV` and `TF_STATE_REGION_DEV`
- an IAM role that can read and write state objects in S3

Instead of creating those pieces manually, this stack lets the customer provision and standardize them with Terraform.

The stack supports two IAM operating models:

- use pre-existing GitHub Actions roles by passing `github_actions_role_arns`
- create the GitHub Actions roles in the stack with `create_github_actions_roles = true`

It also supports two GitHub OIDC provider models:

- reuse the standard provider that already exists in the account
- create it in the stack with `create_github_oidc_provider = true`

## Backend model

This stack is intentionally designed to run with the default local backend.

- It does not depend on the remote state bucket it is creating.
- It can be re-run even if the local state file is lost.
- If the bucket already exists, the stack skips bucket creation and reapplies the supporting S3 settings and IAM access policy.

## Usage

1. Copy [`terraform.tfvars.example`](/Users/alan/workspaces/alan-teodoro/frontline-education/stacks/state-backend/terraform.tfvars.example) to a local `terraform.tfvars`.
2. Choose one IAM mode:

- Pre-existing roles: set `github_actions_role_arns`
- Managed roles: set `create_github_actions_roles = true`, `github_repository_owner`, and `github_repository_name`
- If the AWS account does not already trust GitHub OIDC, also set `create_github_oidc_provider = true`

3. Run:

```bash
cd stacks/state-backend
terraform init
terraform plan
terraform apply
```

## Managed role trust model

When the stack creates GitHub Actions roles, the trust policy allows:

- the configured repository on the allowed branches for non-environment jobs such as plan steps
- the GitHub environments `dev`, `qa`, `stage`, and `prod`
- the destroy environments `destroy-dev`, `destroy-qa`, `destroy-stage`, and `destroy-prod`

That matches the current workflow structure in this repository, where plan jobs do not use GitHub environments but apply and destroy jobs do.

By default, the stack assumes the target AWS account already has the standard GitHub OIDC provider at:

- `arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com`

If the customer account does not already trust GitHub's OIDC provider, enable `create_github_oidc_provider = true` or import the existing provider into the stack.

## Important note for existing buckets

If the bucket already exists, this stack detects that condition and skips the bucket creation step. It then reapplies the supporting configuration to the existing bucket and refreshes the inline IAM policy on each GitHub Actions role.

This stack is intentionally separate from the GitHub Actions workflows. It is an internal bootstrap step that should be run before enabling the customer-facing automation.

## Shared versus per-environment backend

This stack still creates one backend bucket per run. That keeps it simple and works for both operating models:

- Shared backend: run the stack once, set `TF_STATE_BUCKET` and `TF_STATE_REGION`, and let every environment fall back to those global secrets.
- Per-environment backend: run the stack once per environment with different bucket names if desired, then populate `TF_STATE_BUCKET_<ENV>` and `TF_STATE_REGION_<ENV>` for each environment.

If Frontline uses one AWS account and one Redis Cloud account across all environments, the shared backend model remains valid. If they later split AWS accounts or want stricter blast-radius boundaries, the same workflows can switch to per-environment backend secrets without changing the Terraform stacks.

## Outputs to copy into GitHub

If the stack creates the GitHub Actions roles, it returns `managed_github_actions_role_arns` keyed by environment. Use those values to populate these repository variables:

- `AWS_GITHUB_ACTIONS_ROLE_ARN_DEV`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_QA`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_STAGE`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_PROD`

If the stack creates the OIDC provider, it also returns `managed_github_oidc_provider_arn`.
