#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


OWNER = "alan-teodoro"
REPOSITORY = "frontline-education"
WORKFLOW_FILE = "rediscloud-apply.yml"
REF = "main"

# This payload is intentionally hard-coded to demonstrate how an external
# system such as Jira automation could trigger the workflow.
INPUTS = {
    "environment": "dev",
    "subscription_family": "student-solutions",
    "app_name": "student-sessions",
    "purpose": "session",
    "tier": "s",
    "persistence_mode": "snapshot-every-6-hours",
    "data_eviction": "allkeys-lru",
    "application_role_arn": "arn:aws:iam::654654352456:role/GitHubActionsOIDC",
}


def main() -> None:
    github_token = os.getenv("GITHUB_TOKEN")

    if not github_token:
        print("GITHUB_TOKEN must be set", file=sys.stderr)
        sys.exit(1)

    url = f"https://api.github.com/repos/{OWNER}/{REPOSITORY}/actions/workflows/{WORKFLOW_FILE}/dispatches"
    payload = {
        "ref": REF,
        "inputs": INPUTS,
    }

    request = Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {github_token}",
            "X-GitHub-Api-Version": "2022-11-28",
            "Content-Type": "application/json",
            "User-Agent": "frontline-education-jira-simulation/1.0",
        },
        method="POST",
    )

    try:
        with urlopen(request) as response:
            status_code = response.getcode()
    except HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace").strip()
        print(f"GitHub workflow dispatch failed with HTTP {exc.code}", file=sys.stderr)
        if body:
            print(body, file=sys.stderr)
        sys.exit(1)
    except URLError as exc:
        print(f"GitHub workflow dispatch failed: {exc}", file=sys.stderr)
        sys.exit(1)

    print("Workflow dispatch submitted successfully.")
    print(f"Repository: {OWNER}/{REPOSITORY}")
    print(f"Workflow: {WORKFLOW_FILE}")
    print(f"Ref: {REF}")
    print(f"HTTP status: {status_code}")
    print()
    print("Payload:")
    print(json.dumps(payload, indent=2))
    print()
    print(f"Actions URL: https://github.com/{OWNER}/{REPOSITORY}/actions/workflows/{WORKFLOW_FILE}")


if __name__ == "__main__":
    main()
