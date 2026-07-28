-- ============================================================================
-- Onboarding: extra fields captured in the new-agent flow.
-- Adds the columns the onboarding overlay now writes to public.recruits:
--   full street address, shirt size, emergency contact, motivation, the two
--   income questions (need vs. want), and the optional "help you succeed" note.
-- Safe to run once (IF NOT EXISTS guards make it idempotent).
-- ============================================================================

alter table public.recruits
  add column if not exists street                 text,
  add column if not exists shirt_size             text,
  add column if not exists emergency_name         text,
  add column if not exists emergency_phone        text,
  add column if not exists emergency_relationship text,
  add column if not exists motivation             text,
  add column if not exists income_need            text,
  add column if not exists income_want            text,
  add column if not exists help_note              text;
