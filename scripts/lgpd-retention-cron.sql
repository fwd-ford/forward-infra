-- Schedule the LGPD reaper to run daily at 03:00 UTC (midnight in BRT during
-- DST). Apply this in the Supabase Dashboard or via psql as the postgres role
-- AFTER migration 013 is applied.
--
-- Requires the pg_cron extension. Enable it in Supabase via:
--     Dashboard > Database > Extensions > pg_cron > Enable
-- or by running:
--     CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Idempotent unschedule: remove a prior job with the same name, if any.
SELECT cron.unschedule('lgpd-anonymize-expired-customers')
 WHERE EXISTS (
     SELECT 1 FROM cron.job WHERE jobname = 'lgpd-anonymize-expired-customers'
 );

-- Schedule the reaper daily at 03:00 UTC.
SELECT cron.schedule(
    'lgpd-anonymize-expired-customers',
    '0 3 * * *',
    $$ SELECT anonymize_expired_customers(); $$
);

-- Verify:
--   SELECT jobid, jobname, schedule, command, active FROM cron.job
--    WHERE jobname = 'lgpd-anonymize-expired-customers';
