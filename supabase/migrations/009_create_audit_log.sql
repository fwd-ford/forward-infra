-- Migration: 009_create_audit_log
-- Append-only audit trail for critical actions (RBAC changes, mass queries, exports).
-- Required by Cybersecurity discipline rubric (Section 5: Monitoring and Auditing).

CREATE TABLE IF NOT EXISTS audit_log (
    id                  BIGSERIAL PRIMARY KEY,
    actor_id            UUID,
    actor_role          TEXT,
    action              TEXT NOT NULL,
    resource_type       TEXT NOT NULL,
    resource_id         TEXT,
    ip_address          INET,
    user_agent          TEXT,
    request_id          TEXT,
    payload             JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_log_actor ON audit_log (actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_action ON audit_log (action);
CREATE INDEX IF NOT EXISTS idx_audit_log_resource ON audit_log (resource_type, resource_id);
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log (created_at DESC);

COMMENT ON TABLE audit_log IS 'Append-only audit trail for security-sensitive actions. Never UPDATE or DELETE.';

REVOKE UPDATE, DELETE ON audit_log FROM PUBLIC;
