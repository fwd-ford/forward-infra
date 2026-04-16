-- Migration: 008_create_lead_outcomes
-- Closed-loop feedback: the business result of a lead (converted into a service order or lost).
-- Feeds back into forward-ml to improve future scoring.

CREATE TYPE outcome_type AS ENUM ('service_booked', 'service_completed', 'not_interested', 'unreachable', 'churned');

CREATE TABLE IF NOT EXISTS lead_outcomes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id             UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    service_order_id    UUID REFERENCES service_orders(id) ON DELETE SET NULL,
    outcome             outcome_type NOT NULL,
    revenue_brl         NUMERIC(10,2),
    notes               TEXT,
    recorded_by         UUID,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT lead_outcomes_revenue_non_negative CHECK (revenue_brl IS NULL OR revenue_brl >= 0)
);

CREATE INDEX IF NOT EXISTS idx_lead_outcomes_lead ON lead_outcomes (lead_id);
CREATE INDEX IF NOT EXISTS idx_lead_outcomes_outcome ON lead_outcomes (outcome);
CREATE INDEX IF NOT EXISTS idx_lead_outcomes_recorded_at ON lead_outcomes (recorded_at DESC);

COMMENT ON TABLE lead_outcomes IS 'Business outcomes of leads, used for closed-loop ROI and model retraining.';
