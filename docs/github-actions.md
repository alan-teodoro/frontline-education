# GitHub Actions Setup

## Workflows

This repository now includes:

- [`rediscloud-self-service.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/rediscloud-self-service.yml): request-driven create, update, import, and destroy workflow.
- [`terraform-validate.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/terraform-validate.yml): pull request and push validation workflow.

## Required GitHub repository secrets

- `REDISCLOUD_ACCESS_KEY`: Redis Cloud account API key.
- `REDISCLOUD_SECRET_KEY`: Redis Cloud user API key.
- `TF_STATE_BUCKET`: S3 bucket used as the Terraform remote backend.
- `TF_STATE_REGION`: AWS region for the Terraform state bucket.

Mapping reminder:

- Redis Cloud `account key` -> `REDISCLOUD_ACCESS_KEY`
- Redis Cloud user/API secret key -> `REDISCLOUD_SECRET_KEY`

## Required GitHub repository variables

- `REDISCLOUD_PAYMENT_METHOD_ID`: Redis Cloud payment method identifier for the credit card configured on the account.
- `AWS_GITHUB_ACTIONS_ROLE_ARN_DEV`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_QA`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_STAGE`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_PROD`

These role ARNs are used by `aws-actions/configure-aws-credentials` with GitHub OIDC.

The self-service workflow is currently fixed to `payment_method=credit-card`.

## Recommended GitHub environments

Create these GitHub environments:

- `dev`
- `qa`
- `stage`
- `prod`
- `destroy-dev`
- `destroy-qa`
- `destroy-stage`
- `destroy-prod`

Recommended protection settings:

- `dev`: no required reviewers.
- `qa`: add reviewers only if Frontline wants approval in QA.
- `stage`: require reviewers.
- `prod`: require reviewers.
- `destroy-dev`: require reviewers.
- `destroy-qa`: require reviewers.
- `destroy-stage`: require reviewers.
- `destroy-prod`: require reviewers.

The self-service workflow uses:

- `environment: <target-environment>` on apply jobs
- `environment: destroy-<target-environment>` on destroy jobs

That means approvals are enforced by GitHub, not by custom shell logic.

## Backend layout

The workflow uses the S3 backend with native lockfile support (`use_lockfile = true`) and these key patterns:

- subscription state: `subscriptions/<environment>/<subscription_family>.tfstate`
- database state: `databases/<environment>/<subscription_family>/<database_name>.tfstate`

Examples:

- `subscriptions/dev/student-solutions.tfstate`
- `databases/dev/student-solutions/student-sessions-session-dev-s.tfstate`

## Workflow behaviour

### Apply flow

1. Resolve names and backend keys from the request.
2. Discover whether the subscription already exists in Redis Cloud.
3. Discover whether the database already exists in the subscription.
4. Run a Terraform plan for the subscription stack.
5. Run a Terraform plan for the database stack if the subscription already exists.
6. After approval for the target environment, import existing resources into state when needed.
7. Apply the subscription stack.
8. Apply the database stack.
9. Publish the secret name and ARN in the workflow summary.

### Destroy flow

1. Resolve names and backend keys from the request.
2. Discover whether the database and subscription exist.
3. After approval through the dedicated `destroy-<environment>` GitHub environment, import the existing database into state when needed.
4. Destroy the database stack.
5. If `destroy_subscription_if_empty=true`, the workflow checks whether the subscription is empty and only then destroys it.

## Important operational note

If an existing database is being adopted into Terraform for the first time, the workflow automatically imports the subscription and database resources when they already exist in Redis Cloud but are not yet in Terraform state.

It does not attempt to auto-import pre-existing ACL rules, ACL roles, ACL users, or AWS secrets that were created manually outside this repository. Those should either be cleaned up or imported deliberately before first production adoption.
