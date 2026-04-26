#!/usr/bin/env python3
"""
Modify URL schemes in Info.plist to add suffix and avoid conflicts.
"""

import sys
import plistlib
from pathlib import Path


def modify_url_schemes(plist_path, suffix, schemes_to_modify):
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

    # Parse schemes to modify
    schemes_list = [s.strip() for s in schemes_to_modify.split(',')]

    # Modify CFBundleURLSchemes
    if 'CFBundleURLTypes' in plist:
        for url_type in plist['CFBundleURLTypes']:
            if 'CFBundleURLSchemes' in url_type:
                modified_schemes = []
                for scheme in url_type['CFBundleURLSchemes']:
                    # Check if this scheme should be modified
                    should_modify = any(
                        scheme.startswith(prefix) or scheme == prefix
                        for prefix in schemes_list
                    )

                    if should_modify:
                        # Add suffix if not already present
                        if not scheme.endswith(f'-{suffix}'):
                            new_scheme = f"{scheme}-{suffix}"
                            modified_schemes.append(new_scheme)
                        else:
                            modified_schemes.append(scheme)
                    else:
                        modified_schemes.append(scheme)

                url_type['CFBundleURLSchemes'] = modified_schemes

    # Modify LSApplicationQueriesSchemes
    if 'LSApplicationQueriesSchemes' in plist:
        modified_queries = []
        for scheme in plist['LSApplicationQueriesSchemes']:
            # Check if this scheme should be modified
            should_modify = any(
                scheme.startswith(prefix) or scheme == prefix
                for prefix in schemes_list
            )

            if should_modify:
                # Add suffix if not already present
                if not scheme.endswith(f'-{suffix}'):
                    new_scheme = f"{scheme}-{suffix}"
                    modified_queries.append(new_scheme)
                else:
                    modified_queries.append(scheme)
            else:
                modified_queries.append(scheme)

        plist['LSApplicationQueriesSchemes'] = modified_queries

    # Write modified plist
    with open(plist_path, 'wb') as f:
        plistlib.dump(plist, f)

    print(f"Modified URL schemes in {plist_path}")


if __name__ == '__main__':
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <plist_path> <suffix> <schemes_to_modify>")
        print(f"Example: {sys.argv[0]} Payload/KakaoTalk.app/Info.plist 2 kakaotalk,kakaolink")
        sys.exit(1)

    plist_path = sys.argv[1]
    suffix = sys.argv[2]
    schemes_to_modify = sys.argv[3]

    modify_url_schemes(plist_path, suffix, schemes_to_modify)
