#!/usr/bin/env python3
"""
Modify Info.plist for multi-messenger support.
"""

import sys
import plistlib
from pathlib import Path


def modify_plist(info_path, suffix, display_name):
    """
    Modify Info.plist for multi-instance support.

    Args:
        info_path: Path to Info.plist
        suffix: Suffix to add (e.g., "2")
        display_name: Display name (e.g., "KakaoTalk2")
    """
    info_path = Path(info_path)

    if not info_path.exists():
        print(f"Error: {info_path} not found")
        sys.exit(1)

    # Read plist
    with open(info_path, 'rb') as f:
        plist = plistlib.load(f)

    # Get original identifiers
    original_bundle = plist.get('CFBundleIdentifier', '')
    original_group = plist.get('APP_GROUPS_IDENTIFIER', '')
    original_handoff = plist.get('HANDOFF_IDENTIFIER', '')

    # Build new identifiers
    new_bundle = f"{original_bundle}{suffix}"
    new_group = f"{original_group}{suffix}" if original_group else ""
    new_handoff = f"{original_handoff}{suffix}" if original_handoff else ""

    # Modify basic bundle info
    plist['CFBundleIdentifier'] = new_bundle
    plist['CFBundleDisplayName'] = display_name
    plist['CFBundleName'] = display_name

    # Modify group and handoff identifiers
    if new_group:
        plist['APP_GROUPS_IDENTIFIER'] = new_group
    if new_handoff:
        plist['HANDOFF_IDENTIFIER'] = new_handoff

    # Modify CFBundleURLSchemes
    if 'CFBundleURLTypes' in plist:
        for url_type in plist['CFBundleURLTypes']:
            if 'CFBundleURLSchemes' in url_type:
                modified_schemes = []
                for scheme in url_type['CFBundleURLSchemes']:
                    if not scheme.endswith(f'-{suffix}'):
                        new_scheme = f"{scheme}-{suffix}"
                        modified_schemes.append(new_scheme)
                    else:
                        modified_schemes.append(scheme)
                url_type['CFBundleURLSchemes'] = modified_schemes

    # Modify LSApplicationQueriesSchemes
    if 'LSApplicationQueriesSchemes' in plist:
        modified_queries = []
        for scheme in plist['LSApplicationQueriesSchemes']:
            if not scheme.endswith(f'-{suffix}'):
                new_scheme = f"{scheme}-{suffix}"
                modified_queries.append(new_scheme)
            else:
                modified_queries.append(scheme)
        plist['LSApplicationQueriesSchemes'] = modified_queries

    # Modify NSUserActivityTypes
    if 'NSUserActivityTypes' in plist:
        modified_activities = []
        for activity in plist['NSUserActivityTypes']:
            if 'handoff' in activity and not activity.endswith(f'-{suffix}'):
                new_activity = f"{activity}{suffix}"
                modified_activities.append(new_activity)
            else:
                modified_activities.append(activity)
        plist['NSUserActivityTypes'] = modified_activities

    # Modify BGTaskSchedulerPermittedIdentifiers
    if 'BGTaskSchedulerPermittedIdentifiers' in plist:
        modified_bg_tasks = []
        for bg_task in plist['BGTaskSchedulerPermittedIdentifiers']:
            if not bg_task.endswith(f'-{suffix}'):
                new_bg_task = f"{bg_task}{suffix}"
                modified_bg_tasks.append(new_bg_task)
            else:
                modified_bg_tasks.append(bg_task)
        plist['BGTaskSchedulerPermittedIdentifiers'] = modified_bg_tasks

    # Write modified plist
    with open(info_path, 'wb') as f:
        plistlib.dump(plist, f)

    print(f"Modified Info.plist:")
    print(f"  CFBundleIdentifier: {new_bundle}")
    print(f"  CFBundleDisplayName: {display_name}")
    if new_group:
        print(f"  APP_GROUPS_IDENTIFIER: {new_group}")
    if new_handoff:
        print(f"  HANDOFF_IDENTIFIER: {new_handoff}")


if __name__ == '__main__':
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <plist_path> <suffix> <display_name>")
        print(f"Example: {sys.argv[0]} Payload/KakaoTalk.app/Info.plist 2 KakaoTalk2")
        sys.exit(1)

    plist_path = sys.argv[1]
    suffix = sys.argv[2]
    display_name = sys.argv[3]

    modify_plist(plist_path, suffix, display_name)
