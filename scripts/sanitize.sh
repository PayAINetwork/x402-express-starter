#!/usr/bin/env bash
set -euo pipefail
UP_PATH="${1:-examples/typescript/servers/express}"
UP_SHA="${2:-unknown}"

# Keep a mirror for reference (gitignored) and map into template root
mkdir -p vendor/upstream

# Map upstream into template root, preserving structure
mkdir -p template
rsync -a --delete vendor/upstream/ template/

# add the payai facilitator URL in env templates after sync
DEFAULT_FACILITATOR_URL="https://facilitator.payai.network"
update_facilitator_url() {
  local file="$1"
  if [[ -f "$file" ]]; then
    if grep -q '^FACILITATOR_URL=' "$file"; then
      sed -i.bak 's|^FACILITATOR_URL=.*|FACILITATOR_URL=https://facilitator.payai.network|' "$file" && rm -f "$file.bak"
    else
      printf "\nFACILITATOR_URL=%s\n" "$DEFAULT_FACILITATOR_URL" >> "$file"
    fi
  fi
}

update_facilitator_url template/.env-local
update_facilitator_url template/.env.example

# Refresh NOTICE with the commit we synced from
cat > NOTICE <<EOF
This package includes portions derived from coinbase/x402 (${UP_PATH}), Apache-2.0,
commit ${UP_SHA}. See LICENSE and upstream LICENSE notices.
EOF

# Cleanup transient directories so they don't get committed
rm -rf vendor/upstream || true
rm -rf upstream || true

echo "Sanitization complete."

