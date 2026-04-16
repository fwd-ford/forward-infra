#!/usr/bin/env bash
# Applies the seed file to the database pointed to by DATABASE_URL.
# Destructive if run twice: seeds use fixed UUIDs and will conflict on UNIQUE constraints.

set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL not set}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEED_FILE="$SCRIPT_DIR/../supabase/seed/seed.sql"

echo "Applying seed from $SEED_FILE"
psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$SEED_FILE"
echo "Seed applied."
