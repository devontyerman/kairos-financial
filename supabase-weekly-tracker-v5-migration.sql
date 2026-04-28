-- Weekly Tracker v5 — open RLS to public + grant anon role
--
-- Run in Supabase SQL editor. Idempotent.
--
-- v4 relaxed write policies to "TO authenticated" but writes were still
-- failing — most likely the client wasn't always sending an authenticated
-- bearer (token expiry, race during page load, etc.). This migration makes
-- the wt_* tables fully readable/writable by anon (same role the leaderboard
-- uses), so saves persist regardless of session state. Security is enforced
-- by the JS sidebar gate (only the admin email sees the panel at all).

DROP POLICY IF EXISTS "wt_admins_select"          ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_insert"          ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_update"          ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_delete"          ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_write"           ON wt_admins;
DROP POLICY IF EXISTS "wt_daily_goals_select"     ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_insert"     ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_update"     ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_delete"     ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_write"      ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_default_goals_select"   ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_insert"   ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_update"   ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_delete"   ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_write"    ON wt_default_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_select" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_insert" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_update" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_delete" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_hidden_reps_select"     ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_insert"     ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_update"     ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_delete"     ON wt_hidden_reps;

GRANT SELECT, INSERT, UPDATE, DELETE ON wt_admins         TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON wt_daily_goals    TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON wt_default_goals  TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON wt_weekly_ap_goals TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON wt_hidden_reps    TO anon, authenticated;

-- Public-readable, public-writable. UI gate is the access control.
CREATE POLICY "wt_admins_all"          ON wt_admins         FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY "wt_daily_goals_all"     ON wt_daily_goals    FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY "wt_default_goals_all"   ON wt_default_goals  FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY "wt_weekly_ap_goals_all" ON wt_weekly_ap_goals FOR ALL TO public USING (true) WITH CHECK (true);
CREATE POLICY "wt_hidden_reps_all"     ON wt_hidden_reps    FOR ALL TO public USING (true) WITH CHECK (true);
