-- Migration: 007_create_communications
-- Records every message sent to customers (WhatsApp, email, SMS) and their delivery status.
-- Used for audit and to avoid message flooding.

CREATE TYPE communication_channel AS ENUM ('whatsapp', 'email', 'sms', 'push');
CREATE TYPE communication_status  AS ENUM ('queued', 'sent', 'delivered', 'read', 'failed', 'bounced');

CREATE TABLE IF NOT EXISTS communications (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id         UUID NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    lead_id             UUID REFERENCES leads(id) ON DELETE SET NULL,
    channel             communication_channel NOT NULL,
    template_code       TEXT,
    status              communication_status NOT NULL DEFAULT 'queued',
    provider_message_id TEXT,
    payload             JSONB,
    sent_at             TIMESTAMPTZ,
    delivered_at        TIMESTAMPTZ,
    read_at             TIMESTAMPTZ,
    failed_reason       TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_communications_customer ON communications (customer_id);
CREATE INDEX IF NOT EXISTS idx_communications_lead ON communications (lead_id);
CREATE INDEX IF NOT EXISTS idx_communications_status ON communications (status);
CREATE INDEX IF NOT EXISTS idx_communications_sent_at ON communications (sent_at DESC);

COMMENT ON TABLE communications IS 'Outbound communications to customers and their delivery status.';
COMMENT ON COLUMN communications.payload IS 'Provider-specific payload (Zenvia, Twilio, etc.) for debugging and audit.';
