-- Migration: 006_create_leads
-- A lead is an actionable opportunity generated from a churn score.
-- Leads are routed to dealers for follow-up.

CREATE TYPE lead_priority AS ENUM ('low', 'medium', 'high', 'critical');
CREATE TYPE lead_status AS ENUM ('new', 'assigned', 'contacted', 'converted', 'lost', 'expired');

CREATE TABLE IF NOT EXISTS leads (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id         UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    vin                 CHAR(17) REFERENCES vehicles(vin) ON DELETE SET NULL,
    dealer_id           UUID REFERENCES dealers(id) ON DELETE SET NULL,
    score_id            UUID REFERENCES churn_scores(id) ON DELETE SET NULL,
    priority            lead_priority NOT NULL DEFAULT 'medium',
    status              lead_status NOT NULL DEFAULT 'new',
    reason              TEXT,
    expected_value_brl  NUMERIC(10,2),
    assigned_at         TIMESTAMPTZ,
    converted_at        TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT leads_expected_value_non_negative CHECK (expected_value_brl IS NULL OR expected_value_brl >= 0)
);

CREATE INDEX IF NOT EXISTS idx_leads_customer ON leads (customer_id);
CREATE INDEX IF NOT EXISTS idx_leads_dealer ON leads (dealer_id);
CREATE INDEX IF NOT EXISTS idx_leads_status ON leads (status);
CREATE INDEX IF NOT EXISTS idx_leads_priority ON leads (priority);
CREATE INDEX IF NOT EXISTS idx_leads_expires_at ON leads (expires_at) WHERE status IN ('new', 'assigned', 'contacted');

COMMENT ON TABLE leads IS 'Actionable opportunities generated from churn scores, routed to dealers.';
