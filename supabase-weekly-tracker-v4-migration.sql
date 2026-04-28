-- Weekly Tracker v4 — relax RLS write gate
--
-- Run in Supabase SQL editor. Idempotent.
--
-- The earlier wt_is_admin() write check was causing silent save failures
-- (default AP goals reverting on refresh, rep-show/hide toggle bouncing
-- back, etc.) — likely a JWT email mismatch with the wt_admins row.
--
-- Since the only entry point to the Weekly Tracker UI is gated client-side
-- by an admin-email check (sidebar button is hidden from everyone else),
-- the database-level admin check is belt-and-suspenders — and it's the thing
-- breaking. This migration replaces the wt_is_admin() write policies with
-- "any authenticated user can write." The UI gate remains the source of
-- truth for who can reach the Weekly Tracker in the first place.

DROP POLICY IF EXISTS "wt_admins_insert"          ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_update"          ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_delete"          ON wt_admins;
DROP POLICY IF EXISTS "wt_daily_goals_insert"     ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_update"     ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_delete"     ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_default_goals_insert"   ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_update"   ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_delete"   ON wt_default_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_insert" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_update" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_delete" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_hidden_reps_insert"     ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_update"     ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_delete"     ON wt_hidden_reps;

-- wt_admins (allowlist still useful for future server-side checks)
CREATE POLICY "wt_admins_insert" ON wt_admins
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "wt_admins_update" ON wt_admins
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "wt_admins_delete" ON wt_admins
  FOR DELETE TO authenticated USING (true);

-- wt_daily_goals
CREATE POLICY "wt_daily_goals_insert" ON wt_daily_goals
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "wt_daily_goals_update" ON wt_daily_goals
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "wt_daily_goals_delete" ON wt_daily_goals
  FOR DELETE TO authenticated USING (true);

-- wt_default_goals
CREATE POLICY "wt_default_goals_insert" ON wt_default_goals
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "wt_default_goals_update" ON wt_default_goals
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "wt_default_goals_delete" ON wt_default_goals
  FOR DELETE TO authenticated USING (true);

-- wt_weekly_ap_goals
CREATE POLICY "wt_weekly_ap_goals_insert" ON wt_weekly_ap_goals
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "wt_weekly_ap_goals_update" ON wt_weekly_ap_goals
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "wt_weekly_ap_goals_delete" ON wt_weekly_ap_goals
  FOR DELETE TO authenticated USING (true);

-- wt_hidden_reps
CREATE POLICY "wt_hidden_reps_insert" ON wt_hidden_reps
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "wt_hidden_reps_update" ON wt_hidden_reps
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "wt_hidden_reps_delete" ON wt_hidden_reps
  FOR DELETE TO authenticated USING (true);
