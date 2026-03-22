# Frontline Education Redis Cloud Terraform

This repository provides a Terraform-first foundation to automate Redis Cloud Pro subscriptions and databases on AWS for Frontline Education.

The repository now includes both local Terraform stacks and GitHub Actions workflows:

- Provision and manage Redis Cloud Pro subscriptions.
- Provision and manage Redis Cloud databases, ACL rules, ACL roles, and ACL users.
- Disable the default database user by default.
- Disable public endpoints by default at the subscription level.
- Generate application credentials without exposing them in Terraform outputs.
- Store database connection details in AWS Secrets Manager.
- Grant read access to the generated secret to the target AWS IAM application role.
- Create a single default ACL bundle for the application bootstrap user with read/write access.
- Support separate GitHub Actions apply and destroy flows with discovery and import.
- Support environment-specific Redis Cloud credentials so each environment can target a different Redis Cloud account.
- Support either a shared Terraform S3 backend or environment-specific backend bucket and region secrets.
- Support Terraform validation in CI.

## Why the repository is split into two stacks

Redis Cloud has a natural hierarchy:

- One account can contain many subscriptions.
- One subscription can contain many databases.

Because of that, this repository separates state ownership into:

- `stacks/subscription`: owns one Redis Cloud subscription.
- `stacks/database`: owns one Redis Cloud database plus ACL objects, secret storage, and IAM access.

This separation matters for day-2 operations:

- A single subscription can safely host many independent databases.
- Each database request can have its own Terraform state and lifecycle.
- Destroying one database does not endanger the subscription or sibling databases.
- Future GitHub Actions workflows can import and update existing resources without collapsing everything into one state file.

The current naming model assumes one Redis Cloud account per environment. Because of that, environment stays in state keys, tags, secret paths, and GitHub approvals, but it is no longer embedded in Redis resource names. The GitHub Actions controller resolves names in Python and passes them explicitly into Terraform.

## Repository layout

- `config/catalog.yaml`: Frontline Education defaults, environment settings, subscription profiles, and size mappings.
- `docs/naming-convention.md`: naming rules and examples for subscriptions, databases, users, roles, and secrets.
- `docs/architecture.md`: implementation notes and orchestration guidance.
- `docs/backend-bootstrap.md`: internal backend bootstrap stack for the S3 remote state bucket and GitHub Actions IAM access.
- `docs/external-trigger-example.md`: simple example of an external system triggering the GitHub Actions workflow.
- `docs/github-actions.md`: GitHub Actions setup, secrets, variables, and approval model.
- `docs/local-testing.md`: local test workflow using the Git-ignored Redis Cloud credential file.
- `modules/terraform_state_backend`: reusable S3 backend and IAM access module.
- `modules/rediscloud_subscription`: Redis Cloud Pro subscription module.
- `modules/rediscloud_database`: Redis Cloud database module.
- `modules/rediscloud_access_bundle`: ACL user/role/rule, Secrets Manager, and IAM access module.
- `scripts`: helper utilities used by GitHub Actions to resolve names, look up Redis Cloud resources, and generate tfvars files.
- `stacks/subscription`: root stack for a subscription.
- `stacks/database`: root stack for a database request.
- `stacks/state-backend`: internal bootstrap stack for the S3 remote state bucket.
- `.github/workflows/rediscloud-apply.yml`: request-driven apply workflow.
- `.github/workflows/rediscloud-destroy.yml`: request-driven destroy workflow.
- `.github/workflows/terraform-validate.yml`: CI validation workflow.

## Important design decision for subscriptions

Redis Cloud subscription `creation_plan` is only meaningful during subscription creation. In practice, that means the first database request should not define the long-term subscription capacity model.

For that reason, subscription sizing is driven by `subscription_profiles` in [`config/catalog.yaml`](/Users/alan/workspaces/alan-teodoro/frontline-education/config/catalog.yaml), not by an individual database request. The repository now fixes `creation_plan.quantity` to `1` for all subscriptions to keep the initial plan simple and avoid confusing “initial databases” counts in the Redis Cloud UI.

## Local usage

1. Update [`config/catalog.yaml`](/Users/alan/workspaces/alan-teodoro/frontline-education/config/catalog.yaml) with the correct Redis Cloud cloud account names, AWS regions, CIDR ranges, billing settings, and subscription profile values for Frontline Education.
2. Export Redis Cloud API credentials:

```bash
source scripts/use-test-env.sh
```

3. Export AWS credentials for the target environment account.
4. Create the subscription, if needed:

```bash
cd stacks/subscription
terraform init
terraform plan -var-file=terraform.tfvars.example
```

5. Create one database inside an existing subscription:

```bash
cd stacks/database
terraform init
terraform plan -var-file=terraform.tfvars.example
```

## Handling existing resources in CI

Terraform can only update resources it already knows in state. That means future automation must handle pre-existing resources explicitly:

- If the subscription does not exist: create it with `stacks/subscription`.
- If the subscription exists but is not in Terraform state: import it, then apply.
- If the database does not exist: create it with `stacks/database`.
- If the database exists but is not in Terraform state: import it, then apply.

The implemented GitHub Actions model is documented in [`docs/architecture.md`](/Users/alan/workspaces/alan-teodoro/frontline-education/docs/architecture.md) and [`docs/github-actions.md`](/Users/alan/workspaces/alan-teodoro/frontline-education/docs/github-actions.md).

## Test-ready setup

The repository is also prepared for local Redis Cloud API testing through the Git-ignored file [`.env.rediscloud.test.local`](/Users/alan/workspaces/alan-teodoro/frontline-education/.env.rediscloud.test.local). The local test flow is documented in [`docs/local-testing.md`](/Users/alan/workspaces/alan-teodoro/frontline-education/docs/local-testing.md).

The default subscription deployment model in the repository is `managed`, which matches the expected Frontline rollout. For local Redis Cloud BYOC tests, use explicit Terraform overrides instead of changing the customer default.

## Security notes

- Database credentials are not exposed in Terraform outputs.
- The generated ACL user password is stored in Terraform state, so a secure remote backend is mandatory before production rollout.
- The application-facing artifact is the AWS Secrets Manager secret name or ARN, not the raw credential values.

## Backend bootstrap

The S3 backend required by GitHub Actions can be provisioned by the internal stack in [`stacks/state-backend`](/Users/alan/workspaces/alan-teodoro/frontline-education/stacks/state-backend). That stack is documented in [`docs/backend-bootstrap.md`](/Users/alan/workspaces/alan-teodoro/frontline-education/docs/backend-bootstrap.md) and is intended to be run before enabling the customer-facing workflows. The workflows support both a shared backend secret pair and environment-specific backend secret pairs, and the backend stack can either attach access to pre-existing GitHub Actions roles or create the GitHub OIDC provider and repository roles in the customer's AWS account.

## Remaining future work

The next layer after this repository is:

- Jira or service management integration that triggers the workflow automatically.
- Final backend hardening choices such as KMS encryption, access boundaries, and bucket policies.
