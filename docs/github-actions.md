# GitHub Actions Setup

## Workflows

This repository now includes:

- [`rediscloud-apply.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/rediscloud-apply.yml): request-driven create and update workflow.
- [`rediscloud-destroy.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/rediscloud-destroy.yml): request-driven destroy workflow with a reduced input set.
- [`terraform-validate.yml`](/Users/alan/workspaces/alan-teodoro/frontline-education/.github/workflows/terraform-validate.yml): validation workflow for pull requests, pushes to `main`, and manual runs through `workflow_dispatch`.

## Required GitHub repository secrets

- `REDISCLOUD_ACCESS_KEY_DEV`
- `REDISCLOUD_SECRET_KEY_DEV`
- `REDISCLOUD_ACCESS_KEY_QA`
- `REDISCLOUD_SECRET_KEY_QA`
- `REDISCLOUD_ACCESS_KEY_STAGE`
- `REDISCLOUD_SECRET_KEY_STAGE`
- `REDISCLOUD_ACCESS_KEY_PROD`
- `REDISCLOUD_SECRET_KEY_PROD`
- `TF_STATE_BUCKET`: default S3 bucket used as the Terraform remote backend when an environment-specific backend secret is not set.
- `TF_STATE_REGION`: default AWS region for the Terraform state bucket when an environment-specific backend secret is not set.

Optional environment-specific backend secrets:

- `TF_STATE_BUCKET_DEV`
- `TF_STATE_BUCKET_QA`
- `TF_STATE_BUCKET_STAGE`
- `TF_STATE_BUCKET_PROD`
- `TF_STATE_REGION_DEV`
- `TF_STATE_REGION_QA`
- `TF_STATE_REGION_STAGE`
- `TF_STATE_REGION_PROD`

Mapping reminder:

- Redis Cloud `account key` -> `REDISCLOUD_ACCESS_KEY_<ENV>`
- Redis Cloud user/API secret key -> `REDISCLOUD_SECRET_KEY_<ENV>`

## Required GitHub repository variables

- `AWS_GITHUB_ACTIONS_ROLE_ARN_DEV`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_QA`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_STAGE`
- `AWS_GITHUB_ACTIONS_ROLE_ARN_PROD`

These role ARNs are used by `aws-actions/configure-aws-credentials` with GitHub OIDC.

If the backend bootstrap stack creates the roles for you, copy the `managed_github_actions_role_arns` outputs into those repository variables.

Backend resolution order:

- For `dev`, the workflow prefers `TF_STATE_BUCKET_DEV` and `TF_STATE_REGION_DEV`.
- For `qa`, the workflow prefers `TF_STATE_BUCKET_QA` and `TF_STATE_REGION_QA`.
- For `stage`, the workflow prefers `TF_STATE_BUCKET_STAGE` and `TF_STATE_REGION_STAGE`.
- For `prod`, the workflow prefers `TF_STATE_BUCKET_PROD` and `TF_STATE_REGION_PROD`.
- If the environment-specific backend secret is empty or absent, the workflow falls back to `TF_STATE_BUCKET` and `TF_STATE_REGION`.

That means the repository supports both operating models:

- one shared backend bucket for all environments
- one backend bucket per environment

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

Redis Cloud credentials and backend settings are selected from the workflow input environment, so discovery, plan, apply, and destroy all run against the Redis Cloud account and Terraform backend mapped to `dev`, `qa`, `stage`, or `prod`.

## Backend layout

The GitHub Actions workflow writes a temporary S3 backend configuration at runtime, with native lockfile support (`use_lockfile = true`), and uses these key patterns:

- subscription state: `subscriptions/<environment>/<subscription_family>.tfstate`
- database state: `databases/<environment>/<subscription_family>/<database_name>.tfstate`

Examples:

- `subscriptions/dev/student-solutions.tfstate`
- `databases/dev/student-solutions/student-sessions-session.tfstate`

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

### Tier sizing impact

The GitHub Actions interface does not need to change when the Redis Cloud t-shirt catalog is recalibrated, as long as the tier keys remain the same.

For this repository, `s`, `m`, `l`, and `xl` are still the only workflow inputs. The effective Redis Cloud `dataset_size_in_gb` and `throughput_measurement_value` come from [`config/catalog.yaml`](/Users/alan/workspaces/alan-teodoro/frontline-education/config/catalog.yaml), so changing those catalog values changes what GitHub Actions provisions without changing the workflow contract.

Important side effect:

- database requests use the selected `tier` directly
- subscription creation uses `subscription_profiles.<family>.max_tier`, which also resolves through `database_sizes`

That means raising a tier definition can also raise the initial subscription `creation_plan` for any subscription family whose `max_tier` points at that tier.

Database alerts are also derived from [`config/catalog.yaml`](/Users/alan/workspaces/alan-teodoro/frontline-education/config/catalog.yaml). The current repository baseline calculates:

- `dataset-size` directly from the configured percentage
- `throughput-higher-than` from the selected tier throughput multiplied by the configured critical ratio
- `latency` from the configured critical latency threshold

The catalog also stores warning thresholds and Replica Of thresholds for future evolution, but the current Terraform flow applies one Redis Cloud threshold per supported alert type and does not provision Replica Of databases today.

### Destroy workflow

1. Accept a minimal request with `environment`, `subscription_family`, and the exact `database_name`.
2. Resolve the subscription name and backend keys from that request.
3. Discover whether the database and subscription exist.
4. After approval through the dedicated `destroy-<environment>` GitHub environment, import the existing database into state when needed.
5. Destroy the database stack.
6. If `destroy_subscription_if_empty=true`, the workflow checks whether the subscription is empty and only then destroys it.

The destroy workflow intentionally does not ask for creation-only parameters such as persistence mode, eviction policy, or application role ARN.

## Important operational note

If an existing database is being adopted into Terraform for the first time, the workflow automatically imports the subscription and database resources when they already exist in Redis Cloud but are not yet in Terraform state.

It does not attempt to auto-import pre-existing ACL rules, ACL roles, ACL users, or AWS secrets that were created manually outside this repository. Those should either be cleaned up or imported deliberately before first production adoption.
