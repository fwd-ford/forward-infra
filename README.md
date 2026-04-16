# forward-infra

![org](https://img.shields.io/badge/org-fwd--ford-blue?style=flat-square)
![stack](https://img.shields.io/badge/stack-PostgreSQL_·_Supabase_·_Docker-333?style=flat-square)

Database schema, migrations and seed data for **ForwardService**.
Target: Supabase (managed Postgres) in production; plain Postgres via Docker locally.

## Structure

```
supabase/
├── migrations/          Sequential SQL migrations (source of truth)
├── seed/                Synthetic data for dev and demo
└── functions/           Supabase Edge Functions (TBD)
docker/
└── docker-compose.yml   Local Postgres with migrations + seed auto-applied
scripts/
├── apply_migrations.sh  Apply migrations to any DATABASE_URL
└── apply_seed.sh        Apply seed to any DATABASE_URL
```

## Schema overview

| Table | Purpose |
|---|---|
| `dealers` | Ford authorized dealerships in Brazil |
| `customers` | End customers (CPF hashed for anonymized lookups) |
| `vehicles` | Vehicles tracked by VIN |
| `service_orders` | Maintenance history (revisões) per vehicle |
| `churn_scores` | ML output: probability and segment per customer |
| `leads` | Actionable opportunities routed to dealers |
| `communications` | Outbound messages (WhatsApp/email/SMS) |
| `lead_outcomes` | Closed-loop feedback for ML retraining |
| `audit_log` | Append-only audit trail (Cybersecurity requirement) |

## Security

- **Row-Level Security (RLS)** enabled on all tables (migration 010).
- Roles: `user`, `dealer`, `analyst`, `admin`.
- CPF stored in plain column + SHA-256 hash column (for anonymized ML joins).
- `audit_log` is append-only (UPDATE/DELETE revoked from PUBLIC).

## Quick start (local Docker)

```bash
docker compose -f docker/docker-compose.yml up -d
# Postgres listens on localhost:5432, database "forward", user "forward" / password "forward_dev"
# Migrations and seed are auto-applied on first start.
```

To reset:
```bash
docker compose -f docker/docker-compose.yml down -v
docker compose -f docker/docker-compose.yml up -d
```

## Apply migrations to Supabase

```bash
DATABASE_URL="postgresql://postgres:$SUPABASE_DB_PASSWORD@db.<project>.supabase.co:5432/postgres" \
  ./scripts/apply_migrations.sh
```

## Migrations list

| # | File | Purpose |
|---|---|---|
| 001 | `001_create_dealers.sql` | Dealer entities + uniqueness constraints |
| 002 | `002_create_customers.sql` | Customers with CPF hash + LGPD consent |
| 003 | `003_create_vehicles.sql` | Vehicles keyed by VIN |
| 004 | `004_create_service_orders.sql` | Maintenance history with typed status |
| 005 | `005_create_churn_scores.sql` | ML scores with feature snapshot |
| 006 | `006_create_leads.sql` | Leads with priority + status state machine |
| 007 | `007_create_communications.sql` | Outbound messages |
| 008 | `008_create_lead_outcomes.sql` | Business outcomes for closed-loop |
| 009 | `009_create_audit_log.sql` | Append-only audit trail |
| 010 | `010_rls_policies.sql` | Role-based row policies |
| 011 | `011_triggers_updated_at.sql` | Auto updated_at trigger |

## Conventions

- Never modify an applied migration. Create a new one.
- All constraints named explicitly (no defaults like `<table>_check1`).
- Timestamps always `TIMESTAMPTZ`, never naive.
- Monetary values: `NUMERIC(10,2)` in BRL; never `float`.
