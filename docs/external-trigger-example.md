# External Trigger Example

This repository already exposes GitHub Actions workflows as the automation entrypoint. An external tool such as Jira can trigger those workflows by calling the GitHub Actions `workflow_dispatch` API.

For customer demonstrations, the repository includes a minimal example script:

- [`scripts/github_workflow_dispatch_example.py`](/Users/alan/workspaces/alan-teodoro/frontline-education/scripts/github_workflow_dispatch_example.py)

The script is intentionally simple:

- The repository, workflow file, branch, and request payload are hard-coded.
- It uses a GitHub token from `GITHUB_TOKEN`.
- It performs a single `POST` request to the GitHub Actions API.

## Example usage

```bash
export GITHUB_TOKEN="<github-token>"
python3 scripts/github_workflow_dispatch_example.py
```

## What it simulates

The script simulates an external request that asks GitHub Actions to run:

- workflow: `rediscloud-apply.yml`
- branch: `main`
- inputs:
  - `environment=dev`
  - `subscription_family=student-solutions`
  - `app_name=student-sessions`
  - `purpose=session`
  - `tier=s`
  - `persistence_mode=snapshot-every-6-hours`
  - `data_eviction=allkeys-lru`
  - `application_role_arn=arn:aws:iam::654654352456:role/GitHubActionsOIDC`

In a real Jira integration, these values would normally come from ticket fields or automation rules instead of being hard-coded in the script.
