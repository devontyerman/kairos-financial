-- Weekly Tracker v2 — adds dial goals and weekly AP goal
--
-- Run in Supabase SQL editor. Idempotent.
-- Builds on supabase-weekly-tracker-migration.sql (which created the wt_*
-- tables and the wt_is_admin() helper).

-- ─── 1. Add dial_goal columns to existing daily/default goal tables ──
ALTER TABLE wt_daily_goals    ADD COLUMN IF NOT EXISTS dial_goal NUMERIC NOT NULL DEFAULT 0;
ALTER TABLE wt_default_goals  ADD COLUMN IF NOT EXISTS dial_goal NUMERIC NOT NULL DEFAULT 0;

-- ─── 2. Per-week AP goal table (one row per rep per week) ────────────
CREATE TABLE IF NOT EXISTS wt_weekly_ap_goals (
  week_start  DATE      NOT NULL,
  sales_rep   TEXT      NOT NULL,
  ap_goal     NUMERIC   NOT NULL DEFAULT 0,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  TEXT,
  PRIMARY KEY (week_start, sales_rep)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON wt_weekly_ap_goals TO authenticated;
ALTER TABLE wt_weekly_ap_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "wt_weekly_ap_goals_select" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_insert" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_update" ON wt_weekly_ap_goals;
DROP POLICY IF EXISTS "wt_weekly_ap_goals_delete" ON wt_weekly_ap_goals;

CREATE POLICY "wt_weekly_ap_goals_select" ON wt_weekly_ap_goals
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "wt_weekly_ap_goals_insert" ON wt_weekly_ap_goals
  FOR INSERT TO authenticated WITH CHECK (wt_is_admin());
CREATE POLICY "wt_weekly_ap_goals_update" ON wt_weekly_ap_goals
  FOR UPDATE TO authenticated USING (wt_is_admin()) WITH CHECK (wt_is_admin());
CREATE POLICY "wt_weekly_ap_goals_delete" ON wt_weekly_ap_goals
  FOR DELETE TO authenticated USING (wt_is_admin());
