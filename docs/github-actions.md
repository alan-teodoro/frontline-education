# GitHub Actions Setup

## Workflows

This repository now includes:

- [`rediscloud-apply.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/rediscloud-apply.yml): request-driven create and update workflow.
- [`rediscloud-destroy.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/rediscloud-destroy.yml): request-driven destroy workflow.
- [`terraform-validate.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/terraform-validate.yml): pull request and push validation workflow.

## Required GitHub repository secrets

- `REDISCLOUD_ACCESS_KEY_DEV`
- `REDISCLOUD_SECRET_KEY_DEV`
- `REDISCLOUD_ACCESS_KEY_QA`
- `REDISCLOUD_SECRET_KEY_QA`
- `REDISCLOUD_ACCESS_KEY_STAGE`
- `REDISCLOUD_SECRET_KEY_STAGE`
- `REDISCLOUD_ACCESS_KEY_PROD`
- `REDISCLOUD_SECRET_KEY_PROD`
- `TF_STATE_BUCKET`: S3 bucket used as the Terraform remote backend.
- `TF_STATE_REGION`: AWS region for the Terraform state bucket.

Mapping reminder:

- Redis Cloud `account key` -> `REDISCLOUD_ACCESS_KEY_<ENV>`
- Redis Cloud user/API secret key -> `REDISCLOUD_SECRET_KEY_<ENV>`

## Required GitHub repository variables

- `AWS_GITHUB_ACTIONS_ROLE_ARN_DEV`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_QA`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_STAGE`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_PROD`

These role ARNs are used by `aws-actions/configure-aws-credentials` with GitHub OIDC.

Billing is resolved from [`config/catalog.yaml`](/Users/alan/workspaces/alan-teodoro/frontline-education/config/catalog.yaml). For the current test setup, the workflow uses `payment_method=credit-card` and looks up the configured card automatically by `credit_card_type` and `credit_card_last_four`.

If Frontline uses one Redis Cloud account per environment, store a different Redis Cloud API key pair in each environment-specific secret pair above. If multiple environments share the same Redis Cloud account, the same key pair can be copied into more than one suffix.

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

The workflows use:

- `environment: <target-environment>` on apply jobs
- `environment: destroy-<target-environment>` on destroy jobs

That means approvals are enforced by GitHub, not by custom shell logic.

Redis Cloud credentials are selected from the workflow input environment, so discovery, plan, apply, and destroy all run against the Redis Cloud account mapped to `dev`, `qa`, `stage`, or `prod`.

## Backend layout

The GitHub Actions workflow writes a temporary S3 backend configuration at runtime, with native lockfile support (`use_lockfile = true`), and uses these key patterns:

- subscription state: `subscriptions/<environment>/<subscription_family>.tfstate`
- database state: `databases/<environment>/<subscription_family>/<database_name>.tfstate`

Examples:

- `subscriptions/dev/student-solutions.tfstate`
- `databases/dev/student-solutions/student-sessions-session-dev-s.tfstate`

## Workflow behaviour

### Apply workflow

1. Resolve names and backend keys from the request.
2. Discover whether the subscription already exists in Redis Cloud.
3. Discover whether the database already exists in the subscription.
4. Run a Terraform plan for the subscription stack.
5. Run a Terraform plan for the database stack if the subscription already exists.
6. After approval for the target environment, import existing resources into state when needed.
7. Apply the subscription stack.
8. Apply the database stack.
9. Publish the secret name and ARN in the workflow summary.

### Destroy workflow

1. Resolve names and backend keys from the request.
2. Discover whether the database and subscription exist.
3. After approval through the dedicated `destroy-<environment>` GitHub environment, import the existing database into state when needed.
4. Destroy the database stack.
5. If `destroy_subscription_if_empty=true`, the workflow checks whether the subscription is empty and only then destroys it.

## Important operational note

If an existing database is being adopted into Terraform for the first time, the workflow automatically imports the subscription and database resources when they already exist in Redis Cloud but are not yet in Terraform state.

It does not attempt to auto-import pre-existing ACL rules, ACL roles, ACL users, or AWS secrets that were created manually outside this repository. Those should either be cleaned up or imported deliberately before first production adoption.
