#!/usr/bin/env python3
"""
Create minimal sideload entitlements from an app Info.plist.
"""

import argparse
import os
import plistlib
import sys
from pathlib import Path


def as_list(value):
    if not value:
        return []
    if isinstance(value, list):
        return [item for item in value if item]
    return [value]


def unique(values):
    seen = set()
    result = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        result.append(value)
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("info_plist", help="Path to app Info.plist")
    parser.add_argument("output", help="Path to write entitlements plist")
    parser.add_argument(
        "--team-id",
        default=os.environ.get("TEAM_ID", "MV5A7FG3T2"),
        help="Team identifier to use in generated entitlements",
    )
    parser.add_argument(
        "--include-app-groups",
        action="store_true",
        help="Include APP_GROUPS_IDENTIFIER values from Info.plist",
    )
    args = parser.parse_args()

    info_path = Path(args.info_plist)
    if not info_path.exists():
        print(f"Error: {info_path} not found", file=sys.stderr)
        return 1

    with info_path.open("rb") as f:
        info = plistlib.load(f)

    bundle_id = info.get("CFBundleIdentifier")
    if not bundle_id:
        print("Error: CFBundleIdentifier is missing", file=sys.stderr)
        return 1

    team_id = args.team_id.strip()
    if not team_id:
        print("Error: team id is empty", file=sys.stderr)
        return 1

    app_identifier = f"{team_id}.{bundle_id}"
    entitlements = {
        "application-identifier": app_identifier,
        "com.apple.developer.team-identifier": team_id,
        "get-task-allow": True,
        "keychain-access-groups": [app_identifier],
    }

    if args.include_app_groups:
        groups = unique(as_list(info.get("APP_GROUPS_IDENTIFIER")))
        if groups:
            entitlements["com.apple.security.application-groups"] = groups

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("wb") as f:
        plistlib.dump(entitlements, f, sort_keys=False)

    print(f"Created entitlements for {bundle_id}")
    print(f"  application-identifier: {app_identifier}")
    if args.include_app_groups and entitlements.get("com.apple.security.application-groups"):
        print("  app groups: " + ", ".join(entitlements["com.apple.security.application-groups"]))

    return 0


if __name__ == "__main__":
    sys.exit(main())
