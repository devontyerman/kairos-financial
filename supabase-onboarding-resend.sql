-- ============================================================================
-- Admin re-onboarding: lets an admin push an existing agent back through a
-- chosen subset of the onboarding flow.
--   onboarding_steps = array of step ids the agent must complete this time
--                      (NULL/empty = the full flow). Combined with
--                      onboarding_completed=false + onboarding_step reset.
-- Safe to run once.
-- ============================================================================

alter table public.agent_profiles
  add column if not exists onboarding_steps jsonb;
