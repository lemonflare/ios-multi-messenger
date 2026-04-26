#!/usr/bin/env python3
"""
Modify Info.plist for multi-messenger support.
"""

import sys
import plistlib
from pathlib import Path


def append_suffix_once(value, suffix):
    if not value or value.endswith(suffix):
        return value
    return f"{value}{suffix}"


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
    new_bundle = append_suffix_once(original_bundle, suffix)
    new_group = append_suffix_once(original_group, suffix) if original_group else ""
    new_handoff = append_suffix_once(original_handoff, suffix) if original_handoff else ""

    # Modify basic bundle info
    plist['CFBundleIdentifier'] = new_bundle
    plist['CFBundleDisplayName'] = display_name
    plist['CFBundleName'] = display_name

    # Modify group and handoff identifiers
    if new_group:
        plist['APP_GROUPS_IDENTIFIER'] = new_group
    if new_handoff:
        plist['HANDOFF_IDENTIFIER'] = new_handoff

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
