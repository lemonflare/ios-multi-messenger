#!/usr/bin/env python3
"""
Modify Info.plist for multi-messenger support.
"""

import sys
import plistlib
import argparse
from pathlib import Path


def append_suffix_once(value, suffix):
    if not value or value.endswith(suffix):
        return value
    return f"{value}{suffix}"


def replace_identifier_prefix(value, original_bundle, new_bundle, suffix):
    if not value:
        return value

    if original_bundle and original_bundle in value:
        return value.replace(original_bundle, new_bundle)

    # KakaoTalk has a few identifiers using kakaoTalk instead of KakaoTalk.
    if original_bundle == "com.iwilab.KakaoTalk":
        original_kakao_bg = "com.iwilab.kakaoTalk"
        new_kakao_bg = f"{original_kakao_bg}{suffix}"
        if original_kakao_bg in value:
            return value.replace(original_kakao_bg, new_kakao_bg)

    return value


def modify_plist(info_path, suffix, display_name, rewrite_associated_identifiers=True):
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
    new_group = replace_identifier_prefix(original_group, original_bundle, new_bundle, suffix) if original_group else ""
    if new_group == original_group:
        new_group = append_suffix_once(original_group, suffix)

    new_handoff = replace_identifier_prefix(original_handoff, original_bundle, new_bundle, suffix) if original_handoff else ""
    if new_handoff == original_handoff:
        new_handoff = append_suffix_once(original_handoff, suffix)

    # Modify basic bundle info
    plist['CFBundleIdentifier'] = new_bundle
    plist['CFBundleDisplayName'] = display_name
    plist['CFBundleName'] = display_name

    # Modify group and handoff identifiers
    if new_group:
        plist['APP_GROUPS_IDENTIFIER'] = new_group
    if new_handoff:
        plist['HANDOFF_IDENTIFIER'] = new_handoff

    if rewrite_associated_identifiers:
        if 'NSUserActivityTypes' in plist:
            plist['NSUserActivityTypes'] = [
                replace_identifier_prefix(activity, original_bundle, new_bundle, suffix)
                for activity in plist['NSUserActivityTypes']
            ]

        if 'BGTaskSchedulerPermittedIdentifiers' in plist:
            plist['BGTaskSchedulerPermittedIdentifiers'] = [
                replace_identifier_prefix(bg_task, original_bundle, new_bundle, suffix)
                for bg_task in plist['BGTaskSchedulerPermittedIdentifiers']
            ]

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
    parser = argparse.ArgumentParser(
        description="Modify Info.plist for multi-instance support.",
        epilog=f"Example: {sys.argv[0]} Payload/KakaoTalk.app/Info.plist 2 KakaoTalk2",
    )
    parser.add_argument("plist_path")
    parser.add_argument("suffix")
    parser.add_argument("display_name")
    parser.add_argument(
        "--no-associated-identifiers",
        action="store_true",
        help="Do not rewrite NSUserActivityTypes or BGTaskSchedulerPermittedIdentifiers",
    )
    args = parser.parse_args()

    modify_plist(
        args.plist_path,
        args.suffix,
        args.display_name,
        rewrite_associated_identifiers=not args.no_associated_identifiers,
    )
