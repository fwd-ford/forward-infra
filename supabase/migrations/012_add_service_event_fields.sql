-- Migration: 012_add_service_event_fields
-- Adds maintenance_number and main_source to service_orders to capture the
-- dealer-submitted scheduled maintenance sequence and the channel that
-- originated the event (e.g. dealer_app, n8n, manual).

ALTER TABLE service_orders
    ADD COLUMN maintenance_number INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN main_source        TEXT    NOT NULL DEFAULT 'legacy';

ALTER TABLE service_orders
    ALTER COLUMN maintenance_number DROP DEFAULT,
    ALTER COLUMN main_source        DROP DEFAULT;

ALTER TABLE service_orders
    ADD CONSTRAINT service_orders_maintenance_number_non_negative
        CHECK (maintenance_number >= 0);

CREATE INDEX IF NOT EXISTS idx_service_orders_main_source ON service_orders (main_source);

COMMENT ON COLUMN service_orders.maintenance_number IS 'Scheduled maintenance sequence number (e.g. 1st, 2nd, 3rd revision).';
COMMENT ON COLUMN service_orders.main_source        IS 'Channel that originated the event (e.g. dealer_app, n8n, manual).';
