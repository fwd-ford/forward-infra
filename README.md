# forward-infra

![org](https://img.shields.io/badge/org-fwd--ford-blue?style=flat-square)
![stack](https://img.shields.io/badge/stack-Supabase_·_PostgreSQL_·_Docker-333?style=flat-square)

Infrastructure configuration for **ForwardService** — Supabase schema, migrations, seeds, and Docker compose.

## Structure

```
supabase/
├── migrations/       # SQL migrations (sequential, versioned)
├── seed/             # Synthetic data for development and demo
└── functions/        # Supabase Edge Functions (if needed)
docker/
├── docker-compose.yml        # Local dev environment
└── docker-compose.prod.yml   # Production config
scripts/
├── setup.sh          # Initial project setup
├── seed.sh           # Run seed data
└── deploy.sh         # Deploy automation
```

## Migrations

Migrations are numbered sequentially:
```
001_create_dealers.sql
002_create_customers.sql
003_create_vehicles.sql
004_create_service_orders.sql
005_create_churn_scores.sql
006_create_leads.sql
007_create_communications.sql
008_create_lead_outcomes.sql
009_rls_policies.sql
```

## Seed Data

Synthetic data simulating:
- 145 Ford dealerships across Brazil
- Thousands of customers with vehicles (Ka, Fiesta, EcoSport, Ranger, Territory)
- Service order history
- Pre-calculated churn scores
