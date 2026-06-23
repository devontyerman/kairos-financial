-- Discord Scheduler — the SENDER (runs entirely inside Supabase)
--
-- Run this once in the Supabase SQL editor, AFTER supabase-discord-scheduler-migration.sql.
-- Idempotent (safe to re-run).
--
-- What this sets up:
--   1. pg_cron + pg_net extensions (built-in Supabase scheduler + HTTP client)
--   2. discord_config        — one-row table holding your Discord webhook URL
--   3. discord_next_run()     — recurrence math (mirrors the browser), Eastern time
--   4. discord_send_due()     — posts every due message, reschedules recurring ones
--   5. discord_send_test()    — fires a test message on demand (used by the page)
--   6. A pg_cron job that calls discord_send_due() every minute
--
-- The webhook lives in discord_config, locked to admins via RLS. The page lets you
-- paste/save it and send a test — you never put it in code or git.

-- ─── 1. Extensions ──────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- ─── 2. Webhook config (single row, admin-only) ─────────────────────
CREATE TABLE IF NOT EXISTS discord_config (
  id          INT PRIMARY KEY DEFAULT 1,
  webhook_url TEXT,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT discord_config_singleton CHECK (id = 1)
);
INSERT INTO discord_config (id, webhook_url) VALUES (1, '')
  ON CONFLICT (id) DO NOTHING;

GRANT SELECT, INSERT, UPDATE ON discord_config TO authenticated;
ALTER TABLE discord_config ENABLE ROW LEVEL SECURITY;

-- Reuses wt_is_admin() (wt_admins allowlist → dev@kairos-financial.com).
DROP POLICY IF EXISTS "discord_config_admin" ON discord_config;
CREATE POLICY "discord_config_admin" ON discord_config
  FOR ALL TO authenticated USING (wt_is_admin()) WITH CHECK (wt_is_admin());

-- ─── 3. Recurrence math — next UTC instant strictly after p_after ────
-- Times are interpreted as US Eastern (America/New_York); DST handled by
-- Postgres' AT TIME ZONE. Mirrors computeNextRun() in saleshub.html.
CREATE OR REPLACE FUNCTION discord_next_run(
  p_recurrence   TEXT,
  p_send_time    TEXT,
  p_send_date    DATE,
  p_day_of_week  INT,
  p_day_of_month INT,
  p_after        TIMESTAMPTZ
) RETURNS TIMESTAMPTZ
LANGUAGE plpgsql STABLE
AS $$
DECLARE
  tz   TEXT := 'America/New_York';
  t    TIME := COALESCE(NULLIF(p_send_time, ''), '00:00')::TIME;
  base DATE;
  d    DATE;
  cand TIMESTAMPTZ;
  i    INT;
BEGIN
  IF p_recurrence = 'once' THEN
    IF p_send_date IS NULL THEN RETURN NULL; END IF;
    RETURN (p_send_date + t) AT TIME ZONE tz;
  END IF;

  base := (p_after AT TIME ZONE tz)::DATE;
  FOR i IN 0..400 LOOP
    d := base + i;
    IF p_recurrence = 'daily'
       OR (p_recurrence = 'weekdays' AND EXTRACT(DOW FROM d) BETWEEN 1 AND 5)
       OR (p_recurrence = 'weekly'   AND EXTRACT(DOW FROM d) = p_day_of_week)
       OR (p_recurrence = 'monthly'  AND EXTRACT(DAY FROM d) = p_day_of_month)
    THEN
      cand := (d + t) AT TIME ZONE tz;
      IF cand > p_after THEN
        RETURN cand;
      END IF;
    END IF;
  END LOOP;
  RETURN NULL;
END;
$$;

-- ─── 4. Send all due messages ───────────────────────────────────────
CREATE OR REPLACE FUNCTION discord_send_due() RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, net, pg_temp
AS $$
DECLARE
  r      RECORD;
  v_url  TEXT;
  v_next TIMESTAMPTZ;
BEGIN
  SELECT webhook_url INTO v_url FROM discord_config ORDER BY id LIMIT 1;
  IF v_url IS NULL OR v_url = '' THEN
    RAISE NOTICE 'discord_send_due: no webhook configured, skipping';
    RETURN;
  END IF;

  FOR r IN
    SELECT * FROM discord_scheduled_messages
    WHERE active = TRUE AND next_run_at <= NOW()
    ORDER BY next_run_at ASC
    LIMIT 50
  LOOP
    PERFORM net.http_post(
      url     := v_url,
      headers := jsonb_build_object('Content-Type', 'application/json'),
      body    := jsonb_build_object('content', LEFT(r.message, 2000))
    );

    IF r.recurrence = 'once' THEN
      UPDATE discord_scheduled_messages
        SET active = FALSE, last_sent_at = NOW(), updated_at = NOW()
        WHERE id = r.id;
    ELSE
      v_next := discord_next_run(r.recurrence, r.send_time, r.send_date,
                                 r.day_of_week, r.day_of_month, NOW());
      UPDATE discord_scheduled_messages
        SET last_sent_at = NOW(),
            next_run_at  = COALESCE(v_next, r.next_run_at),
            active       = (v_next IS NOT NULL),
            updated_at   = NOW()
        WHERE id = r.id;
    END IF;
  END LOOP;
END;
$$;

-- Only the cron job (postgres) should run this — not API users.
REVOKE EXECUTE ON FUNCTION discord_send_due() FROM PUBLIC;

-- ─── 5. On-demand test message (called by the page) ─────────────────
CREATE OR REPLACE FUNCTION discord_send_test(p_message TEXT)
RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, net, pg_temp
AS $$
DECLARE v_url TEXT;
BEGIN
  IF NOT wt_is_admin() THEN
    RAISE EXCEPTION 'not authorized';
  END IF;
  SELECT webhook_url INTO v_url FROM discord_config ORDER BY id LIMIT 1;
  IF v_url IS NULL OR v_url = '' THEN
    RETURN 'no-webhook';
  END IF;
  PERFORM net.http_post(
    url     := v_url,
    headers := jsonb_build_object('Content-Type', 'application/json'),
    body    := jsonb_build_object('content', LEFT(COALESCE(NULLIF(p_message, ''), '✅ Test message from Sales Hub'), 2000))
  );
  RETURN 'sent';
END;
$$;
GRANT EXECUTE ON FUNCTION discord_send_test(TEXT) TO authenticated;

-- ─── 6. Schedule it: every minute ───────────────────────────────────
-- Unschedule a prior copy first so re-running this file doesn't duplicate it.
DO $$
BEGIN
  PERFORM cron.unschedule('discord-send-due');
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

SELECT cron.schedule('discord-send-due', '* * * * *', $$ SELECT public.discord_send_due(); $$);

-- Handy checks (run manually if you want):
--   SELECT * FROM cron.job;                       -- confirm the job is registered
--   SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;  -- run history
