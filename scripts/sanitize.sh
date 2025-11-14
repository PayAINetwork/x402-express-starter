#!/usr/bin/env bash
set -euo pipefail
UP_PATH="${1:-examples/typescript/servers/express}"
UP_SHA="${2:-unknown}"

# Keep a mirror for reference (gitignored) and map into template root
mkdir -p vendor/upstream

# Map upstream into template root, preserving structure
mkdir -p template
rsync -a --delete vendor/upstream/ template/

# add the payai facilitator URL and NETWORK in env templates after sync
DEFAULT_FACILITATOR_URL="https://facilitator.payai.network"
DEFAULT_NETWORK="solana-devnet"

update_env_values() {
  local file="$1"
  if [[ -f "$file" ]]; then
    # Update or add FACILITATOR_URL
    if grep -q '^FACILITATOR_URL=' "$file"; then
      sed -i.bak 's|^FACILITATOR_URL=.*|FACILITATOR_URL=https://facilitator.payai.network|' "$file" && rm -f "$file.bak"
    else
      printf "\nFACILITATOR_URL=%s\n" "$DEFAULT_FACILITATOR_URL" >> "$file"
    fi

    # Update or add NETWORK
    if grep -q '^NETWORK=' "$file"; then
      sed -i.bak 's|^NETWORK=.*|NETWORK=solana-devnet|' "$file" && rm -f "$file.bak"
    else
      printf "NETWORK=%s\n" "$DEFAULT_NETWORK" >> "$file"
    fi
  fi
}

update_env_values template/.env-local
update_env_values template/.env.example

# Refresh NOTICE with the commit we synced from
cat > NOTICE <<EOF
This package includes portions derived from coinbase/x402 (${UP_PATH}), Apache-2.0,
commit ${UP_SHA}. See LICENSE and upstream LICENSE notices.
EOF

# Cleanup transient directories so they don't get committed
rm -rf vendor/upstream || true
rm -rf upstream || true

echo "Sanitization complete."

