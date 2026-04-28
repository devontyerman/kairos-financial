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

INSERT INTO wt_admins (email) VALUES ('devontyerman@gmail.com')
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

-- ─── 4. Row Level Security ──────────────────────────────────────────
ALTER TABLE wt_admins        ENABLE ROW LEVEL SECURITY;
ALTER TABLE wt_daily_goals   ENABLE ROW LEVEL SECURITY;
ALTER TABLE wt_default_goals ENABLE ROW LEVEL SECURITY;

-- wt_admins: anyone authenticated can read (so client can self-check)
DROP POLICY IF EXISTS "wt_admins_select" ON wt_admins;
CREATE POLICY "wt_admins_select" ON wt_admins
  FOR SELECT TO authenticated USING (true);

-- Only existing admins can edit the allowlist (or use the SQL editor as service role)
DROP POLICY IF EXISTS "wt_admins_write" ON wt_admins;
CREATE POLICY "wt_admins_write" ON wt_admins
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM wt_admins a WHERE a.email = auth.jwt() ->> 'email'))
  WITH CHECK (EXISTS (SELECT 1 FROM wt_admins a WHERE a.email = auth.jwt() ->> 'email'));

-- Daily goals: authenticated users READ, admins WRITE
DROP POLICY IF EXISTS "wt_daily_goals_select" ON wt_daily_goals;
CREATE POLICY "wt_daily_goals_select" ON wt_daily_goals
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "wt_daily_goals_write" ON wt_daily_goals;
CREATE POLICY "wt_daily_goals_write" ON wt_daily_goals
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM wt_admins a WHERE a.email = auth.jwt() ->> 'email'))
  WITH CHECK (EXISTS (SELECT 1 FROM wt_admins a WHERE a.email = auth.jwt() ->> 'email'));

-- Default goals: same pattern
DROP POLICY IF EXISTS "wt_default_goals_select" ON wt_default_goals;
CREATE POLICY "wt_default_goals_select" ON wt_default_goals
  FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "wt_default_goals_write" ON wt_default_goals;
CREATE POLICY "wt_default_goals_write" ON wt_default_goals
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM wt_admins a WHERE a.email = auth.jwt() ->> 'email'))
  WITH CHECK (EXISTS (SELECT 1 FROM wt_admins a WHERE a.email = auth.jwt() ->> 'email'));
