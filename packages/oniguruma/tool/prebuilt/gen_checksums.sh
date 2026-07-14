#!/usr/bin/env bash
# Regenerate packages/oniguruma/prebuilt/checksums.sha256 from the committed
# prebuilt libraries. Run this whenever a prebuilt binary is added or changed.
#
# Paths in the manifest are relative to prebuilt/. The build hook verifies the
# library it is about to bundle against this manifest and fails hard on a
# mismatch, so the manifest MUST match the committed blobs exactly.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
prebuilt="$here/../../prebuilt"
cd "$prebuilt"

# shasum on macOS, sha256sum on Linux — both emit "<hash>  <path>".
if command -v sha256sum >/dev/null 2>&1; then
  SHA="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA="shasum -a 256"
else
  echo "error: need sha256sum or shasum on PATH" >&2
  exit 1
fi

find . -type f \( -name '*.dylib' -o -name '*.so' -o -name '*.dll' \) \
  | sed 's|^\./||' \
  | LC_ALL=C sort \
  | xargs $SHA > checksums.sha256

echo "Wrote $(cd "$prebuilt" && pwd)/checksums.sha256:"
cat checksums.sha256
