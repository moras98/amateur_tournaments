#!/usr/bin/env bash
# Store-ready App Bundle with the real Supabase backend baked in.
#
#   1. cp .release.env.example .release.env   (once) and fill it in
#   2. ./scripts/build-release.sh
#
# Output: build/app/outputs/bundle/release/app-release.aab
# SKIP_TESTS=1 ./scripts/build-release.sh   skips the test gate (not for store).
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .release.env ]]; then
  echo "error: .release.env missing — copy .release.env.example and fill it in." >&2
  exit 1
fi
set -a
# shellcheck disable=SC1091
source .release.env
set +a

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_ANON_KEY:-}" || "$SUPABASE_ANON_KEY" == "<anon key>" ]]; then
  echo "error: SUPABASE_URL / SUPABASE_ANON_KEY not filled in .release.env." >&2
  exit 1
fi

if [[ ! -f android/key.properties ]]; then
  echo "error: android/key.properties missing — the store build must be upload-key signed." >&2
  exit 1
fi

FLUTTER=/home/agustin/snap/flutter/common/flutter/bin/flutter

"$FLUTTER" gen-l10n

if [[ "${SKIP_TESTS:-0}" != "1" ]]; then
  "$FLUTTER" test
fi

"$FLUTTER" build appbundle --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

AAB=build/app/outputs/bundle/release/app-release.aab
echo
echo "Built: $AAB ($(du -h "$AAB" | cut -f1))"
echo "Signer:"
keytool -printcert -jarfile "$AAB" | head -4
echo
echo "IMPORTANT: back up ~/upload-keystore.jks AND the password in"
echo "android/key.properties (password manager) — losing both means asking"
echo "Google for an upload-key reset."
