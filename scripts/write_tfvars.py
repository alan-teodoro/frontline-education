#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def parse_bool(value: str) -> bool:
    return str(value).strip().lower() in {"1", "true", "yes", "y", "on"}


def parse_role_arns(value: str) -> list[str]:
    raw = value.strip()
    if not raw:
        return []

    if raw.startswith("["):
        parsed = json.loads(raw)
        if not isinstance(parsed, list):
            raise ValueError("application_role_arns JSON input must be a list")
        return [str(item).strip() for item in parsed if str(item).strip()]

    normalized = raw.replace("\n", ",")
    return [item.strip() for item in normalized.split(",") if item.strip()]


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
    parser.add_argument("--subscription-name-override")
    parser.add_argument("--deployment-model")
    parser.add_argument("--cloud-account-name-override")
    parser.add_argument("--payment-method")
    parser.add_argument("--payment-method-id")
    parser.add_argument("--app-name")
    parser.add_argument("--purpose")
    parser.add_argument("--tier")
    parser.add_argument("--persistence-mode")
    parser.add_argument("--data-eviction")
    parser.add_argument("--application-role-arns", default="")
    parser.add_argument("--temporary", default="false")
    parser.add_argument("--expiration-date")
    parser.add_argument("--service-account-purpose", default="app")
    parser.add_argument("--access-level", default="readwrite")
    parser.add_argument("--database-name-override")
    parser.add_argument("--secret-name-override")
    args = parser.parse_args()

    if args.stack == "subscription":
        payload = remove_nulls(
            {
                "environment": args.environment,
                "subscription_family": args.subscription_family,
                "subscription_name_override": blank_to_none(args.subscription_name_override),
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
                "subscription_name_override": blank_to_none(args.subscription_name_override),
                "app_name": blank_to_none(args.app_name),
                "purpose": blank_to_none(args.purpose),
                "tier": blank_to_none(args.tier),
                "persistence_mode": blank_to_none(args.persistence_mode),
                "data_eviction": blank_to_none(args.data_eviction),
                "application_role_arns": parse_role_arns(args.application_role_arns),
                "temporary": parse_bool(args.temporary),
                "expiration_date": blank_to_none(args.expiration_date),
                "service_account_purpose": blank_to_none(args.service_account_purpose),
                "access_level": blank_to_none(args.access_level),
                "database_name_override": blank_to_none(args.database_name_override),
                "secret_name_override": blank_to_none(args.secret_name_override),
            }
        )

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
