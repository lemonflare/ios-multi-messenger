#!/usr/bin/env python3
"""
Modify URL schemes in Info.plist to add suffix and avoid conflicts.
"""

import sys
import plistlib
import argparse
from pathlib import Path


def should_modify_scheme(scheme, prefixes, modify_all=False):
    if modify_all:
        return True

    for prefix in prefixes:
        if scheme == prefix:
            return True
        if len(prefix) >= 3 and scheme.startswith(prefix):
            return True
    return False


def append_scheme_suffix(scheme, suffix):
    suffix_text = f'-{suffix}'
    if scheme.endswith(suffix_text):
        return scheme, False
    return f"{scheme}{suffix_text}", True


def modify_url_schemes(
    plist_path,
    suffix,
    schemes_to_modify,
    modify_all=False,
    include_queries=False,
    query_mode="matching",
):
    """
    Modify URL schemes in Info.plist to add suffix.

    Args:
        plist_path: Path to Info.plist
        suffix: Suffix to add (e.g., "2")
        schemes_to_modify: Comma-separated list of scheme prefixes to modify
    """
    plist_path = Path(plist_path)

    if not plist_path.exists():
        print(f"Error: {plist_path} not found")
        sys.exit(1)

    # Read plist
    with open(plist_path, 'rb') as f:
        plist = plistlib.load(f)

    schemes_list = [s.strip() for s in schemes_to_modify.split(',') if s.strip()]
    modify_all = modify_all or any(s.upper() == "ALL" or s == "*" for s in schemes_list)
    if modify_all:
        schemes_list = []
    modified_url_count = 0
    modified_query_count = 0

    # Modify CFBundleURLSchemes
    if 'CFBundleURLTypes' in plist:
        for url_type in plist['CFBundleURLTypes']:
            if 'CFBundleURLSchemes' in url_type:
                modified_schemes = []
                for scheme in url_type['CFBundleURLSchemes']:
                    if should_modify_scheme(scheme, schemes_list, modify_all):
                        new_scheme, changed = append_scheme_suffix(scheme, suffix)
                        modified_schemes.append(new_scheme)
                        if changed:
                            modified_url_count += 1
                    else:
                        modified_schemes.append(scheme)

                url_type['CFBundleURLSchemes'] = modified_schemes

    if include_queries and 'LSApplicationQueriesSchemes' in plist:
        query_all = query_mode == "all"
        modified_queries = []
        for scheme in plist['LSApplicationQueriesSchemes']:
            if should_modify_scheme(scheme, schemes_list, query_all or modify_all):
                new_scheme, changed = append_scheme_suffix(scheme, suffix)
                modified_queries.append(new_scheme)
                if changed:
                    modified_query_count += 1
            else:
                modified_queries.append(scheme)
        plist['LSApplicationQueriesSchemes'] = modified_queries

    # Write modified plist
    with open(plist_path, 'wb') as f:
        plistlib.dump(plist, f)

    print(f"Modified {modified_url_count} URL scheme(s) in {plist_path}")
    if include_queries:
        print(f"Modified {modified_query_count} query scheme(s) in {plist_path}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Modify URL schemes in Info.plist to add a suffix.",
        epilog=f"Example: {sys.argv[0]} Payload/KakaoTalk.app/Info.plist 2 kakaotalk,kakaolink",
    )
    parser.add_argument("plist_path")
    parser.add_argument("suffix")
    parser.add_argument("schemes_to_modify")
    parser.add_argument("--all", action="store_true", help="Modify every CFBundleURLSchemes value")
    parser.add_argument(
        "--include-queries",
        action="store_true",
        help="Also modify LSApplicationQueriesSchemes",
    )
    parser.add_argument(
        "--query-mode",
        choices=("matching", "all"),
        default="matching",
        help="How to modify LSApplicationQueriesSchemes when --include-queries is set",
    )
    args = parser.parse_args()

    modify_url_schemes(
        args.plist_path,
        args.suffix,
        args.schemes_to_modify,
        modify_all=args.all,
        include_queries=args.include_queries,
        query_mode=args.query_mode,
    )
