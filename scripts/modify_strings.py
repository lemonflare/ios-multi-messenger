#!/usr/bin/env python3
"""
Modify InfoPlist.strings file to change display name.
"""

import sys
import re
from pathlib import Path


def modify_strings(strings_path, key, new_value):
    """
    Modify a key-value pair in InfoPlist.strings.

    Args:
        strings_path: Path to InfoPlist.strings
        key: Key to modify (e.g., "CFBundleDisplayName")
        new_value: New value for the key
    """
    strings_path = Path(strings_path)

    if not strings_path.exists():
        print(f"Warning: {strings_path} not found")
        return False

    # Read the file
    with open(strings_path, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Pattern to match the key-value pair
    # Format: "KEY" = "value";
    pattern = rf'^"{re.escape(key)}"\s*=\s*"[^"]*";'

    # Check if key exists
    if not re.search(pattern, content, re.MULTILINE):
        print(f"Warning: Key '{key}' not found in {strings_path}")
        return False

    # Replace the value
    def replace_func(match):
        return f'"{key}" = "{new_value}";'

    new_content = re.sub(pattern, replace_func, content, count=1, flags=re.MULTILINE)

    # Write back
    with open(strings_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

    print(f"Modified {key} in {strings_path}")
    return True


if __name__ == '__main__':
    if len(sys.argv) < 4:
        print(f"Usage: {sys.argv[0]} <strings_path> <key> <new_value>")
        print(f"Example: {sys.argv[0]} Payload/KakaoTalk.app/en.lproj/InfoPlist.strings CFBundleDisplayName KakaoTalk2")
        sys.exit(1)

    strings_path = sys.argv[1]
    key = sys.argv[2]
    new_value = sys.argv[3]

    success = modify_strings(strings_path, key, new_value)
    sys.exit(0 if success else 1)
