-- Migration: 005_create_churn_scores
-- Stores the output of the forward-ml service. Each customer has at most one current
-- score per scoring version; history is preserved for auditing and model evaluation.

CREATE TABLE IF NOT EXISTS churn_scores (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id         UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    vin                 CHAR(17) REFERENCES vehicles(vin) ON DELETE CASCADE,
    model_version       TEXT NOT NULL,
    segment             TEXT NOT NULL,
    churn_probability   NUMERIC(5,4) NOT NULL,
    confidence          NUMERIC(5,4),
    features_snapshot   JSONB,
    computed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_current          BOOLEAN NOT NULL DEFAULT TRUE,

    CONSTRAINT churn_scores_probability_range CHECK (churn_probability BETWEEN 0 AND 1),
    CONSTRAINT churn_scores_confidence_range CHECK (confidence IS NULL OR confidence BETWEEN 0 AND 1),
    CONSTRAINT churn_scores_segment_known CHECK (segment IN ('fiel', 'abandono', 'esquecido', 'economico'))
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_churn_scores_current_per_customer
    ON churn_scores (customer_id, model_version)
    WHERE is_current = TRUE;

CREATE INDEX IF NOT EXISTS idx_churn_scores_segment ON churn_scores (segment);
CREATE INDEX IF NOT EXISTS idx_churn_scores_probability ON churn_scores (churn_probability DESC);
CREATE INDEX IF NOT EXISTS idx_churn_scores_computed_at ON churn_scores (computed_at DESC);

COMMENT ON TABLE churn_scores IS 'Churn probability and segment for each customer, produced by forward-ml.';
COMMENT ON COLUMN churn_scores.segment IS 'Behavioral segment: fiel, abandono, esquecido, economico.';
COMMENT ON COLUMN churn_scores.features_snapshot IS 'JSON snapshot of features used at scoring time, for audit and reproducibility.';
