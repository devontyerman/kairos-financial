-- =====================================================================
-- Profile — Licenses & Ready Numbers
-- Adds two JSONB columns to agent_profiles so each agent can store their
-- state license numbers and carrier writing / ready numbers.
--
-- Shapes (arrays of small objects):
--   state_licenses  → [{ "state": "TX", "number": "1234567" }, ...]
--   carrier_numbers → [{ "carrier": "Americo", "number": "ABC123" }, ...]
--
-- The Profile panel in saleshub.html reads/writes these via the same
-- PATCH-then-POST upsert it already uses for comp_level, so no new table,
-- policy, or grant is required — the columns inherit agent_profiles' RLS.
--
-- SAFE to re-run (idempotent — ADD COLUMN IF NOT EXISTS).
-- Run in: Supabase Dashboard → SQL Editor → New query → paste → Run.
-- =====================================================================

ALTER TABLE public.agent_profiles
  ADD COLUMN IF NOT EXISTS state_licenses  JSONB NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS carrier_numbers JSONB NOT NULL DEFAULT '[]'::jsonb;

-- Verify after running:
select user_id, state_licenses, carrier_numbers
from public.agent_profiles
limit 20;
