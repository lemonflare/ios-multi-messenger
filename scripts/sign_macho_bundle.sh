#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <app_bundle> <main_binary> <entitlements>" >&2
  exit 1
fi

APP="$1"
MAIN_BINARY="$2"
ENTITLEMENTS="$3"

if [ ! -d "$APP" ]; then
  echo "App bundle not found: $APP" >&2
  exit 1
fi

if [ ! -f "$MAIN_BINARY" ]; then
  echo "Main binary not found: $MAIN_BINARY" >&2
  exit 1
fi

if [ ! -f "$ENTITLEMENTS" ]; then
  echo "Entitlements not found: $ENTITLEMENTS" >&2
  exit 1
fi

sign_file() {
  local path="$1"
  chmod u+w "$path" || true
  ldid -S "$path"
  echo "Signed nested Mach-O: $path"
}

while IFS= read -r -d '' candidate; do
  if [ "$candidate" = "$MAIN_BINARY" ]; then
    continue
  fi

  if file "$candidate" | grep -q "Mach-O"; then
    sign_file "$candidate"
  fi
done < <(find "$APP" -type f -print0)

chmod u+w "$MAIN_BINARY" || true
ldid -S"$ENTITLEMENTS" "$MAIN_BINARY"
echo "Signed main binary: $MAIN_BINARY"
