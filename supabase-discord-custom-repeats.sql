-- Discord Scheduler — adds CUSTOM repeat days (e.g. Mon/Wed/Fri)
--
-- Run this once in the Supabase SQL editor, AFTER the first two Discord files.
-- Idempotent (safe to re-run).
--
-- Adds:
--   * discord_scheduled_messages.days_of_week  SMALLINT[]   (0=Sun … 6=Sat)
--   * 'custom' as a valid recurrence value
--   * updates discord_next_run() + discord_send_due() to honor custom days

-- ─── 1. New column + widened recurrence check ───────────────────────
ALTER TABLE discord_scheduled_messages
  ADD COLUMN IF NOT EXISTS days_of_week SMALLINT[];

ALTER TABLE discord_scheduled_messages
  DROP CONSTRAINT IF EXISTS discord_scheduled_messages_recurrence_check;
ALTER TABLE discord_scheduled_messages
  ADD CONSTRAINT discord_scheduled_messages_recurrence_check
  CHECK (recurrence IN ('once','daily','weekdays','weekly','monthly','custom'));

-- ─── 2. Recurrence math — now takes a days_of_week array ─────────────
-- Drop the old 6-arg signature so we can add the days parameter.
DROP FUNCTION IF EXISTS discord_next_run(TEXT, TEXT, DATE, INT, INT, TIMESTAMPTZ);

CREATE OR REPLACE FUNCTION discord_next_run(
  p_recurrence   TEXT,
  p_send_time    TEXT,
  p_send_date    DATE,
  p_day_of_week  INT,
  p_day_of_month INT,
  p_days_of_week SMALLINT[],
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
       OR (p_recurrence = 'custom'   AND EXTRACT(DOW FROM d)::SMALLINT = ANY(COALESCE(p_days_of_week, ARRAY[]::SMALLINT[])))
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

-- ─── 3. Sender — pass days_of_week through to the math ───────────────
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
                                 r.day_of_week, r.day_of_month, r.days_of_week, NOW());
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

REVOKE EXECUTE ON FUNCTION discord_send_due() FROM PUBLIC;
