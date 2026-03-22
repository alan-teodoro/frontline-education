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


def derive_app_and_purpose(app_name: str | None, purpose: str | None, database_name: str | None) -> tuple[str, str]:
    normalized_app = normalize(app_name) if app_name else ""
    normalized_purpose = normalize(purpose) if purpose else ""

    if normalized_app and normalized_purpose:
        return normalized_app, normalized_purpose

    if database_name:
        normalized_database_name = normalize(database_name)
        derived_app, separator, derived_purpose = normalized_database_name.rpartition("-")
        if separator and derived_app and derived_purpose:
            return derived_app, derived_purpose

    return normalized_app, normalized_purpose


def build_names(catalog: dict[str, Any], args: argparse.Namespace) -> dict[str, str]:
    environment = normalize(args.environment)
    subscription_family = normalize(args.subscription_family)
    app_name, purpose = derive_app_and_purpose(args.app_name, args.purpose, args.database_name)
    secret_prefix = catalog.get("secret_settings", {}).get("prefix", "frontline-education/redis").strip("/")

    subscription_name = f"sub-{FRONTLINE_SHORT_CODE}-{subscription_family}"
    database_name = normalize(args.database_name) if args.database_name else f"{app_name}-{purpose}"
    acl_rule_name = f"acl-{subscription_family}-{app_name}-{purpose}" if app_name and purpose else ""
    acl_role_name = f"role-{subscription_family}-{app_name}-{purpose}" if app_name and purpose else ""
    acl_user_name = f"svc-{subscription_family}-{app_name}-{purpose}" if app_name and purpose else ""
    secret_name = f"{secret_prefix}/{environment}/{subscription_family}/{app_name}/{purpose}" if app_name and purpose else ""

    return {
        "app_name": app_name,
        "purpose": purpose,
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
    parser.add_argument("--app-name")
    parser.add_argument("--purpose")
    parser.add_argument("--tier")
    parser.add_argument("--database-name")
    parser.add_argument("--persistence-mode", default="none")
    parser.add_argument("--data-eviction", default="allkeys-lru")
    args = parser.parse_args()

    with Path(args.catalog_file).open("r", encoding="utf-8") as handle:
        catalog = yaml.safe_load(handle)

    names = build_names(catalog, args)
    if args.database_name and (not names["app_name"] or not names["purpose"]):
        parser.error(
            "database_name must follow the <app>-<purpose> naming convention when app_name and purpose are not provided explicitly."
        )

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
