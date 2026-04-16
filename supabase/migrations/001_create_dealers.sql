-- Migration: 001_create_dealers
-- Creates the dealers table representing Ford dealerships in Brazil.
-- There are roughly 145 Ford dealers across Brazilian states (source: Ford Brasil 2026).

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "citext";

CREATE TABLE IF NOT EXISTS dealers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            TEXT NOT NULL UNIQUE,
    name            TEXT NOT NULL,
    cnpj            TEXT NOT NULL UNIQUE,
    city            TEXT NOT NULL,
    state           CHAR(2) NOT NULL,
    region          TEXT NOT NULL,
    address         TEXT,
    phone           TEXT,
    email           CITEXT,
    latitude        NUMERIC(9,6),
    longitude       NUMERIC(9,6),
    active          BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT dealers_state_uppercase CHECK (state = UPPER(state)),
    CONSTRAINT dealers_cnpj_format CHECK (cnpj ~ '^[0-9]{14}$')
);

CREATE INDEX IF NOT EXISTS idx_dealers_state ON dealers (state);
CREATE INDEX IF NOT EXISTS idx_dealers_region ON dealers (region);
CREATE INDEX IF NOT EXISTS idx_dealers_active ON dealers (active) WHERE active = TRUE;

COMMENT ON TABLE dealers IS 'Ford authorized dealerships in Brazil.';
COMMENT ON COLUMN dealers.code IS 'Ford internal dealer code (e.g. F0123).';
COMMENT ON COLUMN dealers.region IS 'Brazilian macro region: Norte, Nordeste, Centro-Oeste, Sudeste, Sul.';
