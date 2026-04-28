-- Weekly Tracker — goal storage + admin allowlist
--
-- Run this once in the Supabase SQL editor. Idempotent (safe to re-run).
--
-- Tables created:
--   wt_admins         — email allowlist for managers who can edit goals
--   wt_daily_goals    — per-week, per-rep, per-day goal overrides
--   wt_default_goals  — per-rep default daily goal (used when no day override)
--
-- RLS: any authenticated user can READ goals (so the spreadsheet renders).
-- Only emails in wt_admins can INSERT/UPDATE/DELETE.
--
-- To grant another manager edit access in the future:
--   INSERT INTO wt_admins (email) VALUES ('newmanager@example.com');

-- ─── 1. Admin allowlist ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wt_admins (
  email TEXT PRIMARY KEY,
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO wt_admins (email) VALUES ('dev@kairos-financial.com')
  ON CONFLICT (email) DO NOTHING;

-- ─── 2. Daily goal overrides ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wt_daily_goals (
  week_start  DATE      NOT NULL,
  sales_rep   TEXT      NOT NULL,
  day_idx     SMALLINT  NOT NULL CHECK (day_idx BETWEEN 0 AND 5),
  goal        NUMERIC   NOT NULL DEFAULT 0,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  TEXT,
  PRIMARY KEY (week_start, sales_rep, day_idx)
);

CREATE INDEX IF NOT EXISTS wt_daily_goals_rep_idx
  ON wt_daily_goals (sales_rep, week_start);

-- ─── 3. Per-rep default daily goal ──────────────────────────────────
CREATE TABLE IF NOT EXISTS wt_default_goals (
  sales_rep   TEXT      PRIMARY KEY,
  goal        NUMERIC   NOT NULL DEFAULT 0,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by  TEXT
);

-- ─── 4. Permissions + Row Level Security ───────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON wt_admins        TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON wt_daily_goals   TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON wt_default_goals TO authenticated;

ALTER TABLE wt_admins        ENABLE ROW LEVEL SECURITY;
ALTER TABLE wt_daily_goals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE wt_default_goals ENABLE ROW LEVEL SECURITY;

-- Helper function: is the current user an admin?
-- SECURITY DEFINER bypasses RLS on wt_admins so policies don't recurse into themselves.
CREATE OR REPLACE FUNCTION wt_is_admin() RETURNS boolean
  LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1 FROM wt_admins
    WHERE email = auth.jwt() ->> 'email'
  );
$$;
GRANT EXECUTE ON FUNCTION wt_is_admin() TO authenticated;

-- Drop any prior policies (handles re-runs from earlier versions of this script)
DROP POLICY IF EXISTS "wt_admins_select"        ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_write"         ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_insert"        ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_update"        ON wt_admins;
DROP POLICY IF EXISTS "wt_admins_delete"        ON wt_admins;
DROP POLICY IF EXISTS "wt_daily_goals_select"   ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_write"    ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_insert"   ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_update"   ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_daily_goals_delete"   ON wt_daily_goals;
DROP POLICY IF EXISTS "wt_default_goals_select" ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_write"  ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_insert" ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_update" ON wt_default_goals;
DROP POLICY IF EXISTS "wt_default_goals_delete" ON wt_default_goals;

-- wt_admins: anyone authenticated reads, only admins write
CREATE POLICY "wt_admins_select" ON wt_admins
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "wt_admins_insert" ON wt_admins
  FOR INSERT TO authenticated WITH CHECK (wt_is_admin());
CREATE POLICY "wt_admins_update" ON wt_admins
  FOR UPDATE TO authenticated USING (wt_is_admin()) WITH CHECK (wt_is_admin());
CREATE POLICY "wt_admins_delete" ON wt_admins
  FOR DELETE TO authenticated USING (wt_is_admin());

-- wt_daily_goals: anyone authenticated reads, only admins write
CREATE POLICY "wt_daily_goals_select" ON wt_daily_goals
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "wt_daily_goals_insert" ON wt_daily_goals
  FOR INSERT TO authenticated WITH CHECK (wt_is_admin());
CREATE POLICY "wt_daily_goals_update" ON wt_daily_goals
  FOR UPDATE TO authenticated USING (wt_is_admin()) WITH CHECK (wt_is_admin());
CREATE POLICY "wt_daily_goals_delete" ON wt_daily_goals
  FOR DELETE TO authenticated USING (wt_is_admin());

-- wt_default_goals: anyone authenticated reads, only admins write
CREATE POLICY "wt_default_goals_select" ON wt_default_goals
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "wt_default_goals_insert" ON wt_default_goals
  FOR INSERT TO authenticated WITH CHECK (wt_is_admin());
CREATE POLICY "wt_default_goals_update" ON wt_default_goals
  FOR UPDATE TO authenticated USING (wt_is_admin()) WITH CHECK (wt_is_admin());
CREATE POLICY "wt_default_goals_delete" ON wt_default_goals
  FOR DELETE TO authenticated USING (wt_is_admin());
