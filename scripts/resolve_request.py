#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
from typing import Any

import yaml

FRONTLINE_SHORT_CODE = "fle"


def normalize(value: str) -> str:
    cleaned = re.sub(r"[^a-z0-9-]", "-", value.lower())
    cleaned = re.sub(r"-+", "-", cleaned)
    return cleaned.strip("-")


def parse_bool(value: str) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}


def build_names(catalog: dict[str, Any], args: argparse.Namespace) -> dict[str, str]:
    environment = normalize(args.environment)
    subscription_family = normalize(args.subscription_family)
    app_name = normalize(args.app_name)
    purpose = normalize(args.purpose)
    tier = normalize(args.tier)
    service_account_purpose = normalize(args.service_account_purpose)
    access_level = normalize(args.access_level)
    secret_prefix = catalog.get("secret_settings", {}).get("prefix", "frontline-education/redis").strip("/")

    expiration_suffix = ""
    if parse_bool(args.temporary) and args.expiration_date:
        expiration_suffix = f"_expire{args.expiration_date.replace('-', '')}"

    subscription_name = args.subscription_name_override or f"sub-{FRONTLINE_SHORT_CODE}-{subscription_family}-{environment}"
    database_name = args.database_name_override or (
        f"{app_name}-{purpose}-{environment}-{tier}{expiration_suffix}"
    )
    acl_rule_name = f"acl-{subscription_family}-{app_name}-{purpose}-{environment}-{access_level}"
    acl_role_name = (
        f"role-{subscription_family}-{app_name}-{purpose}-{environment}-{service_account_purpose}-{access_level}"
    )
    acl_user_name = f"svc-{subscription_family}-{app_name}-{purpose}-{environment}-{service_account_purpose}"
    secret_name = args.secret_name_override or f"{secret_prefix}/{environment}/{subscription_family}/{app_name}/{purpose}"

    return {
        "subscription_name": subscription_name,
        "database_name": database_name,
        "acl_rule_name": acl_rule_name,
        "acl_role_name": acl_role_name,
        "acl_user_name": acl_user_name,
        "secret_name": secret_name,
    }


def write_outputs(outputs: dict[str, Any]) -> None:
    github_output = os.getenv("GITHUB_OUTPUT")
    if github_output:
        with open(github_output, "a", encoding="utf-8") as handle:
            for key, value in outputs.items():
                if isinstance(value, (dict, list)):
                    handle.write(f"{key}={json.dumps(value)}\n")
                else:
                    handle.write(f"{key}={value}\n")
    else:
        print(json.dumps(outputs, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="Resolve request metadata for the GitHub Actions workflow.")
    parser.add_argument("--catalog-file", default="config/catalog.yaml")
    parser.add_argument("--operation", required=True)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--subscription-family", required=True)
    parser.add_argument("--app-name", required=True)
    parser.add_argument("--purpose", required=True)
    parser.add_argument("--tier", required=True)
    parser.add_argument("--persistence-mode", default="none")
    parser.add_argument("--data-eviction", default="allkeys-lru")
    parser.add_argument("--application-role-arns", default="")
    parser.add_argument("--temporary", default="false")
    parser.add_argument("--expiration-date")
    parser.add_argument("--service-account-purpose", default="app")
    parser.add_argument("--access-level", default="readwrite")
    parser.add_argument("--subscription-name-override")
    parser.add_argument("--database-name-override")
    parser.add_argument("--secret-name-override")
    args = parser.parse_args()

    with Path(args.catalog_file).open("r", encoding="utf-8") as handle:
        catalog = yaml.safe_load(handle)

    names = build_names(catalog, args)
    environment = normalize(args.environment)
    subscription_family = normalize(args.subscription_family)

    outputs = {
        **names,
        "operation": args.operation,
        "environment": environment,
        "subscription_family": subscription_family,
        "subscription_state_key": f"subscriptions/{environment}/{subscription_family}.tfstate",
        "database_state_key": f"databases/{environment}/{subscription_family}/{names['database_name']}.tfstate",
        "github_environment": environment,
    }
    write_outputs(outputs)


if __name__ == "__main__":
    main()
