# Local Testing

## Redis Cloud test credentials

This repository is prepared for local testing with a Git-ignored environment file:

- [`.env.rediscloud.test.local`](/Users/alan/workspaces/alan-teodoro/frontline-education/.env.rediscloud.test.local)

That file exports:

- `REDISCLOUD_ACCESS_KEY`
- `REDISCLOUD_SECRET_KEY`

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

## Configure GitHub repository secrets with the same credentials

If the target repository is already configured in GitHub CLI:

```bash
./scripts/configure-github-secrets.sh
```

This script sets:

- `REDISCLOUD_ACCESS_KEY`
- `REDISCLOUD_SECRET_KEY`

It does not create the AWS backend secrets or repository variables, because those are specific to Frontline's AWS environments and GitHub repository settings.
