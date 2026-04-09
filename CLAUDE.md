# forward-infra — Repository Instructions

## Language Policy

- SQL: English for identifiers (table names, column names, function names).
- Comments in SQL: English.
- Seed data content: Portuguese (pt-BR) for realistic names, addresses, etc.

## Database Schema

Source of truth: the latest migration files in `supabase/migrations/`.
Always read the migrations to understand the current database state.

## Critical Rules

- NEVER modify a migration that has already been applied. Create a new migration instead.
- Migrations must be idempotent when possible (use IF NOT EXISTS, etc.).
- RLS policies are defined in a dedicated migration (009_rls_policies.sql).
- Seed data must be realistic and consistent (valid VINs, real Brazilian city names, plausible dates).

## Supabase CLI

Use the Supabase CLI for local development:
```bash
supabase init          # Initialize (already done)
supabase start         # Start local Supabase
supabase db push       # Apply migrations to remote
supabase db reset      # Reset local DB and re-apply migrations + seed
```
