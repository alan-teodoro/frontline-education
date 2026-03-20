#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import sys
from typing import Any, Iterable
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen


API_BASE_DEFAULT = "https://api.redislabs.com/v1"
USER_AGENT = "frontline-education-rediscloud-automation/1.0"


def api_get(path: str, api_base: str, headers: dict[str, str], params: dict[str, Any] | None = None) -> Any:
    query = f"?{urlencode(params)}" if params else ""
    request = Request(f"{api_base.rstrip('/')}{path}{query}", headers=headers)
    with urlopen(request) as response:
        return json.loads(response.read().decode("utf-8"))


def describe_http_error(exc: HTTPError) -> str:
    details = f"HTTP {exc.code}"

    try:
        raw_body = exc.read().decode("utf-8").strip()
    except Exception:
        raw_body = ""

    if raw_body:
        details = f"{details}: {raw_body}"
    elif exc.reason:
        details = f"{details}: {exc.reason}"

    if exc.code in {401, 403}:
        details = (
            f"{details}. Check REDISCLOUD_ACCESS_KEY and REDISCLOUD_SECRET_KEY, "
            "and confirm the API key pair has permission to list subscriptions."
        )

    return details


def walk(node: Any) -> Iterable[dict[str, Any]]:
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from walk(value)
    elif isinstance(node, list):
        for item in node:
            yield from walk(item)


def extract_subscriptions(payload: Any) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    seen: set[str] = set()

    for item in walk(payload):
        sub_id = item.get("subscriptionId") or item.get("id")
        name = item.get("name")
        if not sub_id or not name:
            continue
        if item.get("databaseId") or item.get("datasetSizeInGb") is not None:
            continue
        key = str(sub_id)
        if key in seen:
            continue
        seen.add(key)
        results.append({"id": str(sub_id), "name": str(name)})

    return results


def extract_databases(payload: Any) -> list[dict[str, Any]]:
    results: list[dict[str, Any]] = []
    seen: set[str] = set()

    for item in walk(payload):
        db_id = item.get("databaseId") or item.get("dbId")
        name = item.get("name")
        if not db_id or not name:
            continue
        key = str(db_id)
        if key in seen:
            continue
        seen.add(key)
        results.append({"id": str(db_id), "name": str(name)})

    return results


def write_outputs(outputs: dict[str, Any]) -> None:
    github_output = os.getenv("GITHUB_OUTPUT")
    if github_output:
        with Path(github_output).open("a", encoding="utf-8") as handle:
            for key, value in outputs.items():
                if isinstance(value, (dict, list)):
                    handle.write(f"{key}={json.dumps(value)}\n")
                else:
                    handle.write(f"{key}={value}\n")
    else:
        print(json.dumps(outputs, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="Look up Redis Cloud subscriptions and databases.")
    parser.add_argument("--subscription-name", required=True)
    parser.add_argument("--database-name")
    parser.add_argument("--api-base", default=API_BASE_DEFAULT)
    args = parser.parse_args()

    access_key = os.getenv("REDISCLOUD_ACCESS_KEY")
    secret_key = os.getenv("REDISCLOUD_SECRET_KEY")

    if not access_key or not secret_key:
        print("REDISCLOUD_ACCESS_KEY and REDISCLOUD_SECRET_KEY must be set", file=sys.stderr)
        sys.exit(1)

    headers = {
        "x-api-key": access_key,
        "x-api-secret-key": secret_key,
        "Accept": "application/json",
        "User-Agent": USER_AGENT,
    }

    try:
        subscriptions_payload = api_get("/subscriptions", args.api_base, headers, {"offset": 0, "limit": 100})
    except HTTPError as exc:
        print(f"Failed to query Redis Cloud subscriptions: {describe_http_error(exc)}", file=sys.stderr)
        sys.exit(1)
    except URLError as exc:
        print(f"Failed to query Redis Cloud subscriptions: {exc}", file=sys.stderr)
        sys.exit(1)

    subscriptions = extract_subscriptions(subscriptions_payload)
    subscription = next((item for item in subscriptions if item["name"] == args.subscription_name), None)

    outputs: dict[str, Any] = {
        "subscription_exists": str(subscription is not None).lower(),
        "subscription_id": subscription["id"] if subscription else "",
        "database_exists": "false",
        "database_id": "",
        "subscription_database_count": "0",
    }

    if subscription:
        try:
            databases_payload = api_get(
                f"/subscriptions/{subscription['id']}/databases",
                args.api_base,
                headers,
                {"offset": 0, "limit": 100},
            )
        except HTTPError as exc:
            print(
                "Failed to query Redis Cloud databases for "
                f"subscription {subscription['id']}: {describe_http_error(exc)}",
                file=sys.stderr,
            )
            sys.exit(1)
        except URLError as exc:
            print(f"Failed to query Redis Cloud databases for subscription {subscription['id']}: {exc}", file=sys.stderr)
            sys.exit(1)

        databases = extract_databases(databases_payload)
        outputs["subscription_database_count"] = str(len(databases))

        if args.database_name:
            database = next((item for item in databases if item["name"] == args.database_name), None)
            outputs["database_exists"] = str(database is not None).lower()
            outputs["database_id"] = database["id"] if database else ""

    write_outputs(outputs)


if __name__ == "__main__":
    main()
