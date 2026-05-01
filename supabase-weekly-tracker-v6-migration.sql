-- Weekly Tracker v6 — adds monthly AP goal table
--
-- Run in Supabase SQL editor. Idempotent.
-- Builds on v1–v5 migrations.
--
-- Stores one AP goal per (month, sales rep). The month_start column is the
-- first day of the month (e.g. 2026-05-01 for May 2026). UI uses this to
-- render the new "MTD Goal" column on each weekly sheet — every week that
-- falls inside the same month reads from / writes to the same row.

CREATE TABLE IF NOT EXISTS wt_monthly_ap_goals (
  month_start DATE        NOT NULL,
  sales_rep   TEXT        NOT NULL,
  ap_goal     NUMERIC     NOT NULL DEFAULT 0,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  TEXT,
  PRIMARY KEY (month_start, sales_rep)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON wt_monthly_ap_goals TO anon, authenticated;
ALTER TABLE wt_monthly_ap_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "wt_monthly_ap_goals_select" ON wt_monthly_ap_goals;
DROP POLICY IF EXISTS "wt_monthly_ap_goals_insert" ON wt_monthly_ap_goals;
DROP POLICY IF EXISTS "wt_monthly_ap_goals_update" ON wt_monthly_ap_goals;
DROP POLICY IF EXISTS "wt_monthly_ap_goals_delete" ON wt_monthly_ap_goals;
DROP POLICY IF EXISTS "wt_monthly_ap_goals_all"    ON wt_monthly_ap_goals;

-- Public-readable, public-writable. UI sidebar gate is the access control,
-- matching the v5 policy posture for the other wt_* tables.
CREATE POLICY "wt_monthly_ap_goals_all" ON wt_monthly_ap_goals
  FOR ALL TO public USING (true) WITH CHECK (true);
