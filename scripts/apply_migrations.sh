#!/usr/bin/env bash
# Applies all migrations in order against the database pointed to by DATABASE_URL.
# Usage: DATABASE_URL=postgres://... ./scripts/apply_migrations.sh

set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL not set}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MIGRATIONS_DIR="$SCRIPT_DIR/../supabase/migrations"

echo "Applying migrations from $MIGRATIONS_DIR"
for f in $(ls "$MIGRATIONS_DIR"/*.sql | sort); do
    echo "==> $(basename "$f")"
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"
done

echo "Migrations applied successfully."
