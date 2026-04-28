-- Weekly Tracker v3 — hide reps from weekly sheets
--
-- Run in Supabase SQL editor. Idempotent.
-- Builds on supabase-weekly-tracker-migration.sql + v2-migration.sql.

CREATE TABLE IF NOT EXISTS wt_hidden_reps (
  sales_rep   TEXT      PRIMARY KEY,
  hidden_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  hidden_by   TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE ON wt_hidden_reps TO authenticated;
ALTER TABLE wt_hidden_reps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "wt_hidden_reps_select" ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_insert" ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_update" ON wt_hidden_reps;
DROP POLICY IF EXISTS "wt_hidden_reps_delete" ON wt_hidden_reps;

CREATE POLICY "wt_hidden_reps_select" ON wt_hidden_reps
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "wt_hidden_reps_insert" ON wt_hidden_reps
  FOR INSERT TO authenticated WITH CHECK (wt_is_admin());
CREATE POLICY "wt_hidden_reps_update" ON wt_hidden_reps
  FOR UPDATE TO authenticated USING (wt_is_admin()) WITH CHECK (wt_is_admin());
CREATE POLICY "wt_hidden_reps_delete" ON wt_hidden_reps
  FOR DELETE TO authenticated USING (wt_is_admin());
