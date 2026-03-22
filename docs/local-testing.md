# Local Testing

## Redis Cloud test credentials

This repository is prepared for local testing with a Git-ignored environment file:

- [`.env.rediscloud.test.local`](/Users/alan/workspaces/alan-teodoro/frontline-education/.env.rediscloud.test.local)

That file exports:

- `REDISCLOUD_ACCESS_KEY`
- `REDISCLOUD_SECRET_KEY`
- `REDISCLOUD_ACCOUNT_ID` (optional, for documentation/bootstrap only)

Mapping reminder:

- Redis Cloud `account key` -> `REDISCLOUD_ACCESS_KEY`
- Redis Cloud user/API secret key -> `REDISCLOUD_SECRET_KEY`

These environment variables are used by:

- the Redis Cloud Terraform provider
- the helper lookup script
- the GitHub Actions logic when mirrored into repository secrets

## Load the local test credentials

Run:

```bash
source scripts/use-test-env.sh
```

## Quick API connectivity test

After loading the credentials, you can verify authentication with:

```bash
python3 scripts/rediscloud_lookup.py --subscription-name does-not-need-to-exist
```

If authentication is working, the script should return a JSON payload rather than an authentication error.

## Local BYOC override for personal testing

The repository default is `managed`, which matches the customer target design.

For local BYOC-only tests, add these overrides to a local tfvars file for [`stacks/subscription`](/Users/alan/workspaces/alan-teodoro/frontline-education/stacks/subscription):

```hcl
deployment_model         = "byoc"
cloud_account_name_override = "AWS Professional Services"
```

The `AWS Professional Services` cloud account name was discovered from the current test Redis Cloud account through the Redis Cloud API. Do not keep that override in the customer baseline unless they actually plan to use BYOC.

The repository also includes local-only `terraform.tfvars` files for [`stacks/subscription`](/Users/alan/workspaces/alan-teodoro/frontline-education/stacks/subscription) and [`stacks/database`](/Users/alan/workspaces/alan-teodoro/frontline-education/stacks/database). The main value you typically need to replace before a real local apply is the AWS account id inside `application_role_arn`.

For local work, the stacks now use the default local backend automatically. The S3 backend is injected only by GitHub Actions during CI/CD runs.

## Configure GitHub repository secrets with the same credentials

If the target repository is already configured in GitHub CLI:

```bash
./scripts/configure-github-secrets.sh dev
```

This script sets:

- `REDISCLOUD_ACCESS_KEY_DEV`
- `REDISCLOUD_SECRET_KEY_DEV`
- optionally `REDISCLOUD_ACCOUNT_ID_DEV` when `REDISCLOUD_ACCOUNT_ID` is present in the local env file

It does not create the AWS backend secrets or repository variables, because those are specific to Frontline's AWS environments and GitHub repository settings.

For the backend, the workflows now support either:

- shared repository secrets: `TF_STATE_BUCKET` and `TF_STATE_REGION`
- environment-specific repository secrets such as `TF_STATE_BUCKET_DEV` and `TF_STATE_REGION_DEV`

If you only have one AWS account, you can keep using the shared backend secrets or point every environment-specific secret to the same bucket and region.

For the current personal test setup, the Redis Cloud account id is `1977930`. The customer design can still use different Redis Cloud accounts per environment by populating the `QA`, `STAGE`, and `PROD` credential pairs separately.
