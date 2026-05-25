# forward-infra

![org](https://img.shields.io/badge/org-fwd--ford-blue?style=flat-square)
![stack](https://img.shields.io/badge/stack-PostgreSQL_·_Supabase_·_Docker-333?style=flat-square)
![sprint](https://img.shields.io/badge/sprint--1-shipped-success?style=flat-square)
![project](https://img.shields.io/badge/supabase_project-ysewoopjgdpvnkfhffgy_(sa--east--1)-blueviolet?style=flat-square)

Database schema, migrations and seed data for **ForwardService**.
Target: Supabase (managed Postgres) in production; plain Postgres via Docker locally.

## Structure

```text
supabase/
├── migrations/          Sequential SQL migrations (source of truth)
├── seed/                Synthetic data for dev and demo
└── functions/           Supabase Edge Functions (TBD)
docker/
├── docker-compose.yml          Local Postgres + init script
├── docker-compose.supabase.yml API container pointing to remote Supabase
└── init-db.sh                  Bootstrap script applied on first boot
scripts/
├── apply_migrations.sh         Apply migrations to any DATABASE_URL
├── apply_seed.sh               Apply seed to any DATABASE_URL
└── lgpd-retention-cron.sql     Daily reaper job (anonymize_expired_customers)
BACKUP_RESTORE.md       Operational runbook (RPO, RTO, restore drill)
```

## Schema overview

| Table | Purpose |
| --- | --- |
| `dealers` | Ford authorized dealerships in Brazil |
| `customers` | End customers (CPF hashed for anonymized lookups, LGPD consent column) |
| `vehicles` | Vehicles tracked by VIN |
| `service_orders` | Maintenance history (revisoes) per vehicle |
| `churn_scores` | ML output: probability and segment per customer |
| `leads` | Actionable opportunities routed to dealers |
| `communications` | Outbound messages (WhatsApp/email/SMS) |
| `lead_outcomes` | Closed-loop feedback for ML retraining |
| `audit_log` | Append-only audit trail (Cybersecurity requirement) |

## Security and LGPD

- **Row-Level Security (RLS)** enabled on all user-data tables (migration `010`).
- Roles: `user`, `dealer`, `analyst`, `admin`.
- CPF stored in plain column + SHA-256 hash column (for anonymized ML joins).
- `audit_log` is append-only: `REVOKE UPDATE, DELETE ... FROM PUBLIC` in `009`.
- **LGPD retention** (`013`): `anonymize_customer(uuid)` preserves FKs by nulling PII; `anonymize_expired_customers()` reaper runs daily with a 30-day cooling-off window.
- Threat model and OWASP mapping live in [forward-docs/academic/cyber/](../forward-docs/academic/cyber/).
- Backup, restore and PITR strategy in [BACKUP_RESTORE.md](BACKUP_RESTORE.md).

## Quick start (local Docker)

```bash
cd docker
docker compose up -d
# Postgres listens on localhost:55432, database "forward", user "forward" / password "forward_dev"
# Migrations and seed are auto-applied on first start by init-db.sh.
```

To reset:

```bash
docker compose down -v
docker compose up -d
```

For the full local loop (Supabase + API + Mobile), see
[RUNNING_LOCALLY.md](../RUNNING_LOCALLY.md).

## Apply migrations to Supabase

```bash
DATABASE_URL="postgresql://postgres:$SUPABASE_DB_PASSWORD@db.<project>.supabase.co:5432/postgres" \
  ./scripts/apply_migrations.sh
```

Production project: `ysewoopjgdpvnkfhffgy` (sa-east-1). All 13 migrations applied; advisor checks (security + performance) ran green at last deploy.

## Migrations list

| # | File | Purpose |
| --- | --- | --- |
| 001 | `001_create_dealers.sql` | Dealer entities + uniqueness constraints |
| 002 | `002_create_customers.sql` | Customers with CPF hash + LGPD consent |
| 003 | `003_create_vehicles.sql` | Vehicles keyed by VIN |
| 004 | `004_create_service_orders.sql` | Maintenance history with typed status |
| 005 | `005_create_churn_scores.sql` | ML scores with feature snapshot |
| 006 | `006_create_leads.sql` | Leads with priority + status state machine |
| 007 | `007_create_communications.sql` | Outbound messages |
| 008 | `008_create_lead_outcomes.sql` | Business outcomes for closed-loop |
| 009 | `009_create_audit_log.sql` | Append-only audit trail (UPDATE/DELETE revoked) |
| 010 | `010_rls_policies.sql` | Role-based row policies |
| 011 | `011_triggers_updated_at.sql` | Auto `updated_at` trigger |
| 012 | `012_add_service_event_fields.sql` | `maintenance_number` + `main_source` on `service_orders` |
| 013 | `013_lgpd_retention_policy.sql` | `anonymize_customer()` + daily reaper + audit hook |

## Seed data

`supabase/seed/seed.sql` populates a realistic Brazilian fixture: 10+ dealers across all regions, customers with valid-ish CPFs and Brazilian addresses, vehicles with plausible VINs, and service history per persona (loyal, lapsed, recent, etc) aligned with the four pilares in [forward-docs/project/00_BASE_FUNDACIONAL.md](../forward-docs/project/00_BASE_FUNDACIONAL.md).

Never run seed against production.

## Conventions

- Never modify an applied migration; create a follow-up one instead.
- All constraints named explicitly (no defaults like `<table>_check1`).
- Timestamps always `TIMESTAMPTZ`, never naive.
- Monetary values: `NUMERIC(10,2)` in BRL; never `float`.
- SQL identifiers and comments in English; seed content in pt-BR.
- Migrations must be idempotent (`IF NOT EXISTS`, `CREATE OR REPLACE`, `DROP ... IF EXISTS`).

## Operational runbooks

| Task | Where |
| --- | --- |
| Backup, restore, PITR | [BACKUP_RESTORE.md](BACKUP_RESTORE.md) |
| Apply migrations to any DB | `scripts/apply_migrations.sh` |
| Apply seed to any DB | `scripts/apply_seed.sh` |
| Schedule the LGPD reaper | `scripts/lgpd-retention-cron.sql` |
| Full local loop with API + Mobile | [RUNNING_LOCALLY.md](../RUNNING_LOCALLY.md) |
