-- Migration: 010_rls_policies
-- Row-Level Security policies. Required by Cybersecurity discipline (Section 2: RBAC).
-- Roles: user (end customer), analyst (Ford HQ staff), admin (platform admin), dealer (dealership staff).

ALTER TABLE dealers          ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers        ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicles         ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_orders   ENABLE ROW LEVEL SECURITY;
ALTER TABLE churn_scores     ENABLE ROW LEVEL SECURITY;
ALTER TABLE leads            ENABLE ROW LEVEL SECURITY;
ALTER TABLE communications   ENABLE ROW LEVEL SECURITY;
ALTER TABLE lead_outcomes    ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log        ENABLE ROW LEVEL SECURITY;

-- Helper function: extracts role from current Supabase JWT.
-- Gets the current user's role from the JWT / Extrai o role do JWT do usuario atual.
CREATE OR REPLACE FUNCTION auth_role() RETURNS TEXT AS $$
    SELECT COALESCE(
        current_setting('request.jwt.claims', true)::jsonb ->> 'role',
        'anon'
    );
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION auth_user_id() RETURNS UUID AS $$
    SELECT NULLIF(current_setting('request.jwt.claims', true)::jsonb ->> 'sub', '')::UUID;
$$ LANGUAGE sql STABLE;

-- Dealers: readable by all authenticated, writable by admin only.
CREATE POLICY dealers_read ON dealers FOR SELECT USING (auth_role() IN ('user', 'analyst', 'admin', 'dealer'));
CREATE POLICY dealers_write ON dealers FOR ALL USING (auth_role() = 'admin') WITH CHECK (auth_role() = 'admin');

-- Customers: self-read for user, dealers see their own customers, analyst/admin see all.
CREATE POLICY customers_self ON customers FOR SELECT USING (id = auth_user_id() OR auth_role() IN ('analyst', 'admin', 'dealer'));
CREATE POLICY customers_admin_write ON customers FOR ALL USING (auth_role() IN ('analyst', 'admin')) WITH CHECK (auth_role() IN ('analyst', 'admin'));

-- Vehicles: customer sees own, dealer sees assigned, analyst/admin see all.
CREATE POLICY vehicles_visibility ON vehicles FOR SELECT USING (
    customer_id = auth_user_id()
    OR auth_role() IN ('analyst', 'admin')
    OR (auth_role() = 'dealer' AND current_dealer_id IS NOT NULL)
);

-- Churn scores: never exposed to end users. Analyst/admin only.
CREATE POLICY churn_scores_internal ON churn_scores FOR SELECT USING (auth_role() IN ('analyst', 'admin'));

-- Leads: dealer sees own, analyst/admin see all.
CREATE POLICY leads_dealer_scope ON leads FOR SELECT USING (
    auth_role() IN ('analyst', 'admin')
    OR (auth_role() = 'dealer' AND dealer_id IS NOT NULL)
);

-- Audit log: read-only for admin, never for other roles.
CREATE POLICY audit_log_admin_only ON audit_log FOR SELECT USING (auth_role() = 'admin');
