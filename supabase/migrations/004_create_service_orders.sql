-- Migration: 004_create_service_orders
-- Service orders (revisões) performed by dealers on customer vehicles.
-- This table is the source of truth for the "stayed in the network vs left" signal.

CREATE TYPE service_order_status AS ENUM (
    'scheduled',
    'in_progress',
    'completed',
    'cancelled',
    'no_show'
);

CREATE TYPE service_order_type AS ENUM (
    'scheduled_maintenance',
    'recall',
    'warranty_repair',
    'paid_repair',
    'inspection'
);

CREATE TABLE IF NOT EXISTS service_orders (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vin                 CHAR(17) NOT NULL REFERENCES vehicles(vin) ON DELETE CASCADE,
    dealer_id           UUID NOT NULL REFERENCES dealers(id) ON DELETE RESTRICT,
    order_type          service_order_type NOT NULL,
    status              service_order_status NOT NULL DEFAULT 'scheduled',
    scheduled_at        TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    mileage_km          INTEGER,
    total_amount_brl    NUMERIC(10,2),
    notes               TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT service_orders_mileage_non_negative CHECK (mileage_km IS NULL OR mileage_km >= 0),
    CONSTRAINT service_orders_amount_non_negative CHECK (total_amount_brl IS NULL OR total_amount_brl >= 0),
    CONSTRAINT service_orders_completed_requires_date CHECK (status <> 'completed' OR completed_at IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_service_orders_vin ON service_orders (vin);
CREATE INDEX IF NOT EXISTS idx_service_orders_dealer ON service_orders (dealer_id);
CREATE INDEX IF NOT EXISTS idx_service_orders_status ON service_orders (status);
CREATE INDEX IF NOT EXISTS idx_service_orders_completed_at ON service_orders (completed_at);

COMMENT ON TABLE service_orders IS 'Service history for each vehicle, across any dealer in the network.';
