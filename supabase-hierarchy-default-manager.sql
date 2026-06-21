-- Agent Hierarchy — default new agents' manager to the owner
--
-- Run in Supabase SQL editor. Idempotent.
--
-- When a new agent_profiles row is created (by the handle_new_user() signup
-- trigger OR the frontend fallback insert), this BEFORE INSERT trigger ties
-- the agent directly to the owner by setting manager_user_id to the owner's
-- user id — unless a manager was already provided, or the new row IS the
-- owner. The org owner is resolved by email so no UUID is hardcoded.
--
-- It also backfills existing agents that currently have no manager (other than
-- the owner) so the whole org rolls up under the owner until reassigned. The
-- Agent Hierarchy drag-to-reparent UI overwrites manager_user_id, so this is
-- only a default — moving someone in the chart still sticks.

-- ── owner-default trigger ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.kf_default_manager_to_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  owner_id UUID;
BEGIN
  SELECT id INTO owner_id
  FROM auth.users
  WHERE lower(email) = 'dev@kairos-financial.com'
  LIMIT 1;

  IF NEW.manager_user_id IS NULL
     AND owner_id IS NOT NULL
     AND NEW.user_id <> owner_id THEN
    NEW.manager_user_id := owner_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS kf_default_manager_to_owner_trg ON public.agent_profiles;
CREATE TRIGGER kf_default_manager_to_owner_trg
  BEFORE INSERT ON public.agent_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.kf_default_manager_to_owner();

-- ── one-time backfill of existing un-managed agents ──────────────────────
UPDATE public.agent_profiles ap
SET manager_user_id = o.id
FROM (
  SELECT id FROM auth.users WHERE lower(email) = 'dev@kairos-financial.com' LIMIT 1
) o
WHERE ap.manager_user_id IS NULL
  AND ap.user_id <> o.id;
