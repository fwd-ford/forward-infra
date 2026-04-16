-- Migration: 003_create_vehicles
-- Vehicles sold by Ford Brasil, indexed by VIN (Vehicle Identification Number).
-- Brazil has approximately 12.4M active Ford VINs, with ~80% being discontinued models
-- (Ka, Fiesta, EcoSport, Fusion). Active models: Ranger, Territory, Maverick, Bronco, Mustang.

CREATE TABLE IF NOT EXISTS vehicles (
    vin                 CHAR(17) PRIMARY KEY,
    customer_id         UUID REFERENCES customers(id) ON DELETE SET NULL,
    current_dealer_id   UUID REFERENCES dealers(id) ON DELETE SET NULL,
    model               TEXT NOT NULL,
    year                SMALLINT NOT NULL,
    version             TEXT,
    color               TEXT,
    license_plate       TEXT UNIQUE,
    discontinued        BOOLEAN NOT NULL DEFAULT FALSE,
    purchase_date       DATE,
    last_service_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT vehicles_vin_format CHECK (vin ~ '^[A-HJ-NPR-Z0-9]{17}$'),
    CONSTRAINT vehicles_year_range CHECK (year BETWEEN 1990 AND 2030)
);

CREATE INDEX IF NOT EXISTS idx_vehicles_customer_id ON vehicles (customer_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_dealer_id ON vehicles (current_dealer_id);
CREATE INDEX IF NOT EXISTS idx_vehicles_model ON vehicles (model);
CREATE INDEX IF NOT EXISTS idx_vehicles_discontinued ON vehicles (discontinued);
CREATE INDEX IF NOT EXISTS idx_vehicles_last_service_at ON vehicles (last_service_at);

COMMENT ON TABLE vehicles IS 'Ford vehicles tracked by VIN. Core entity of the platform.';
COMMENT ON COLUMN vehicles.vin IS 'ISO 3779 Vehicle Identification Number (17 chars, no I/O/Q).';
COMMENT ON COLUMN vehicles.discontinued IS 'TRUE for models Ford Brasil no longer manufactures locally.';
