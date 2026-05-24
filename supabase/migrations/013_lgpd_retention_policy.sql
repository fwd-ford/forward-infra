-- Migration: 013_lgpd_retention_policy
-- LGPD (Lei 13.709/2018) art. 16: dados pessoais devem ser eliminados apos
-- o termino do tratamento. This migration implements:
--   1) An explicit deletion-request marker so customers can opt out.
--   2) An anonymization function that nullifies PII but preserves the row
--      (keeps FK integrity for service_events, leads, churn_scores).
--   3) A reaper function that anonymizes expired rows in bulk; intended to
--      be invoked by a daily pg_cron job (see scripts/lgpd-retention-cron.sql).
--   4) An audit_log entry per anonymized customer (non-repudiation).

-- 1) Track explicit deletion requests
ALTER TABLE customers
    ADD COLUMN IF NOT EXISTS lgpd_deletion_requested_at TIMESTAMPTZ;

COMMENT ON COLUMN customers.lgpd_deletion_requested_at IS
    'Set when the customer (or staff on their behalf) requests data deletion. '
    'After a 30-day cooling-off window the anonymize_expired_customers reaper '
    'nullifies PII for this row. Audit_log entry is written on anonymization.';

-- 2) Anonymize a single customer
CREATE OR REPLACE FUNCTION anonymize_customer(target_id UUID, reason TEXT DEFAULT 'lgpd_request')
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    affected INTEGER;
BEGIN
    UPDATE customers
       SET full_name       = '[ANONYMIZED]',
           cpf             = NULL,
           birth_date      = NULL,
           email           = NULL,
           phone           = NULL,
           city            = NULL,
           state           = NULL,
           opt_in_whatsapp = FALSE,
           opt_in_email    = FALSE,
           updated_at      = NOW()
     WHERE id = target_id
       AND full_name <> '[ANONYMIZED]';
    GET DIAGNOSTICS affected = ROW_COUNT;

    IF affected > 0 THEN
        INSERT INTO audit_log (action, resource_type, resource_id, payload)
        VALUES (
            'anonymize',
            'customer',
            target_id::TEXT,
            jsonb_build_object('reason', reason, 'at', NOW())
        );
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END;
$$;

COMMENT ON FUNCTION anonymize_customer(UUID, TEXT) IS
    'Nullifies PII fields for a single customer and writes an audit_log entry. '
    'Returns TRUE if a row was actually anonymized. Idempotent: noop if already anonymized.';

-- 3) Bulk reaper: candidates are
--    (a) explicit deletion requests older than 30 days (cooling-off), OR
--    (b) records with no LGPD consent ever, older than 12 months.
CREATE OR REPLACE FUNCTION anonymize_expired_customers()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    candidate UUID;
    total     INTEGER := 0;
BEGIN
    FOR candidate IN
        SELECT id FROM customers
         WHERE full_name <> '[ANONYMIZED]'
           AND (
                (lgpd_deletion_requested_at IS NOT NULL
                 AND lgpd_deletion_requested_at < NOW() - INTERVAL '30 days')
                OR
                (lgpd_consent_at IS NULL
                 AND created_at < NOW() - INTERVAL '12 months')
           )
    LOOP
        IF anonymize_customer(candidate, 'retention_policy') THEN
            total := total + 1;
        END IF;
    END LOOP;
    RETURN total;
END;
$$;

COMMENT ON FUNCTION anonymize_expired_customers() IS
    'Reaper to be called daily by pg_cron. Returns count of newly anonymized '
    'customers. See scripts/lgpd-retention-cron.sql for the schedule definition.';

-- Restrict execution to service role / admin only.
REVOKE EXECUTE ON FUNCTION anonymize_customer(UUID, TEXT) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION anonymize_expired_customers() FROM PUBLIC;
