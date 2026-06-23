-- Discord Scheduler — stores scheduled / recurring Discord messages
--
-- Run this once in the Supabase SQL editor. Idempotent (safe to re-run).
--
-- Table created:
--   discord_scheduled_messages — one row per scheduled or recurring message
--
-- Access model:
--   * Browser (Sales Hub admin) reads/writes via RLS, gated to wt_is_admin()
--     (reuses the existing admin allowlist: wt_admins → dev@kairos-financial.com).
--   * The Trigger.dev sender uses the Supabase SERVICE ROLE key, which bypasses
--     RLS entirely, so it can read due rows and update next_run_at / last_sent_at.
--
-- All times are stored as UTC (timestamptz). The wall-clock time the admin picks
-- is interpreted as US Eastern (America/New_York) by the browser, which converts
-- it to the correct UTC instant before saving. The sender does the same math when
-- it reschedules a recurring message.

-- ─── Table ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS discord_scheduled_messages (
  id            UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  message       TEXT         NOT NULL,
  -- 'once' | 'daily' | 'weekdays' | 'weekly' | 'monthly'
  recurrence    TEXT         NOT NULL DEFAULT 'once'
                  CHECK (recurrence IN ('once','daily','weekdays','weekly','monthly')),
  send_time     TEXT,        -- 'HH:MM' Eastern, used by all recurring types
  send_date     DATE,        -- 'YYYY-MM-DD' Eastern, used by 'once' only
  day_of_week   SMALLINT     CHECK (day_of_week BETWEEN 0 AND 6),   -- 0=Sun, weekly only
  day_of_month  SMALLINT     CHECK (day_of_month BETWEEN 1 AND 31), -- monthly only
  next_run_at   TIMESTAMPTZ  NOT NULL,   -- next UTC instant to fire
  last_sent_at  TIMESTAMPTZ,
  active        BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- The sender polls on this every minute.
CREATE INDEX IF NOT EXISTS discord_scheduled_due_idx
  ON discord_scheduled_messages (next_run_at)
  WHERE active = TRUE;

-- ─── Permissions + Row Level Security ──────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON discord_scheduled_messages TO authenticated;
ALTER TABLE discord_scheduled_messages ENABLE ROW LEVEL SECURITY;

-- Reuses wt_is_admin() from supabase-weekly-tracker-migration.sql.
-- (That function checks the wt_admins allowlist, which contains
--  dev@kairos-financial.com.) Run that migration first if it hasn't been.

DROP POLICY IF EXISTS "discord_sched_select" ON discord_scheduled_messages;
DROP POLICY IF EXISTS "discord_sched_insert" ON discord_scheduled_messages;
DROP POLICY IF EXISTS "discord_sched_update" ON discord_scheduled_messages;
DROP POLICY IF EXISTS "discord_sched_delete" ON discord_scheduled_messages;

-- Admin-only across the board — this is private scheduling data.
CREATE POLICY "discord_sched_select" ON discord_scheduled_messages
  FOR SELECT TO authenticated USING (wt_is_admin());
CREATE POLICY "discord_sched_insert" ON discord_scheduled_messages
  FOR INSERT TO authenticated WITH CHECK (wt_is_admin());
CREATE POLICY "discord_sched_update" ON discord_scheduled_messages
  FOR UPDATE TO authenticated USING (wt_is_admin()) WITH CHECK (wt_is_admin());
CREATE POLICY "discord_sched_delete" ON discord_scheduled_messages
  FOR DELETE TO authenticated USING (wt_is_admin());
