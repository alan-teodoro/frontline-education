#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def remove_nulls(payload: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in payload.items() if value is not None}


def blank_to_none(value: str | None) -> str | None:
    if value is None:
        return None
    return value if value.strip() else None


def main() -> None:
    parser = argparse.ArgumentParser(description="Write JSON tfvars files for a stack.")
    parser.add_argument("--stack", choices=["subscription", "database"], required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--environment", required=True)
    parser.add_argument("--subscription-family", required=True)
    parser.add_argument("--subscription-name")
    parser.add_argument("--deployment-model")
    parser.add_argument("--cloud-account-name-override")
    parser.add_argument("--payment-method")
    parser.add_argument("--payment-method-id")
    parser.add_argument("--app-name")
    parser.add_argument("--purpose")
    parser.add_argument("--tier")
    parser.add_argument("--persistence-mode")
    parser.add_argument("--data-eviction")
    parser.add_argument("--application-role-arn")
    parser.add_argument("--database-name")
    parser.add_argument("--acl-rule-name")
    parser.add_argument("--acl-role-name")
    parser.add_argument("--acl-user-name")
    parser.add_argument("--secret-name")
    args = parser.parse_args()

    if args.stack == "subscription":
        payload = remove_nulls(
            {
                "environment": args.environment,
                "subscription_family": args.subscription_family,
                "subscription_name": blank_to_none(args.subscription_name),
                "deployment_model": blank_to_none(args.deployment_model),
                "cloud_account_name_override": blank_to_none(args.cloud_account_name_override),
                "payment_method": blank_to_none(args.payment_method),
                "payment_method_id": blank_to_none(args.payment_method_id),
            }
        )
    else:
        payload = remove_nulls(
            {
                "environment": args.environment,
                "subscription_family": args.subscription_family,
                "subscription_name": blank_to_none(args.subscription_name),
                "app_name": blank_to_none(args.app_name),
                "purpose": blank_to_none(args.purpose),
                "tier": blank_to_none(args.tier),
                "persistence_mode": blank_to_none(args.persistence_mode),
                "data_eviction": blank_to_none(args.data_eviction),
                "application_role_arn": blank_to_none(args.application_role_arn),
                "database_name": blank_to_none(args.database_name),
                "acl_rule_name": blank_to_none(args.acl_rule_name),
                "acl_role_name": blank_to_none(args.acl_role_name),
                "acl_user_name": blank_to_none(args.acl_user_name),
                "secret_name": blank_to_none(args.secret_name),
            }
        )

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
