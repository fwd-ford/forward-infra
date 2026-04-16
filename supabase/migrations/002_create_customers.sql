-- Migration: 002_create_customers
-- Stores customer records. Sensitive fields (CPF, phone, email) are kept in a separate
-- column hash so we can search/match without exposing raw values on non-privileged roles.

CREATE TABLE IF NOT EXISTS customers (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    full_name           TEXT NOT NULL,
    cpf                 TEXT UNIQUE,
    cpf_hash            TEXT GENERATED ALWAYS AS (encode(digest(cpf, 'sha256'), 'hex')) STORED,
    birth_date          DATE,
    email               CITEXT,
    phone               TEXT,
    city                TEXT,
    state               CHAR(2),
    opt_in_whatsapp     BOOLEAN NOT NULL DEFAULT FALSE,
    opt_in_email        BOOLEAN NOT NULL DEFAULT FALSE,
    lgpd_consent_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT customers_cpf_format CHECK (cpf IS NULL OR cpf ~ '^[0-9]{11}$'),
    CONSTRAINT customers_state_uppercase CHECK (state IS NULL OR state = UPPER(state))
);

CREATE INDEX IF NOT EXISTS idx_customers_cpf_hash ON customers (cpf_hash);
CREATE INDEX IF NOT EXISTS idx_customers_state ON customers (state);
CREATE INDEX IF NOT EXISTS idx_customers_opt_in_whatsapp ON customers (opt_in_whatsapp) WHERE opt_in_whatsapp = TRUE;

COMMENT ON TABLE customers IS 'End customers who bought a Ford vehicle through the dealer network.';
COMMENT ON COLUMN customers.cpf_hash IS 'SHA-256 of CPF, used for anonymized lookups in ML pipelines.';
COMMENT ON COLUMN customers.lgpd_consent_at IS 'Timestamp of LGPD consent (Brazilian GDPR equivalent).';
