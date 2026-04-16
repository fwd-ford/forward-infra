#!/bin/bash
# Runs all migrations in order, then the seed. Invoked by the official postgres
# image entrypoint when the data directory is empty.
# Executa todas as migrations em ordem e depois o seed.
set -euo pipefail

for f in /migrations/*.sql; do
    echo "Applying migration: $f"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f "$f"
done

if [ -f /seed/seed.sql ]; then
    echo "Applying seed"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /seed/seed.sql
fi
