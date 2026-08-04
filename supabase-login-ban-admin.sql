-- ============================================================================
-- Login ban visibility + reversal (admin only)
-- ----------------------------------------------------------------------------
-- Removing an agent (archive_agent_user / delete_agent_user) sets
-- auth.users.banned_until, which is what produces the "User is banned" error
-- at sign-in. The only reversal in the UI used to be the Unarchive button,
-- which renders solely for agent_profiles.status = 'inactive'. If a banned
-- agent's profile goes back to active any other way — re-run through
-- onboarding, a manual status edit — the ban is stranded with no way to see
-- or clear it from the hub.
--
-- These two functions let the Agent Profiles page show the real auth-level ban
-- state and lift it. Both are admin-only; agent_profiles has no ban column, so
-- everything reads through to auth.users.
--
-- Safe to run more than once.
-- ============================================================================

-- 1. Which agents are banned in Supabase Auth. Returns nothing at all for
--    non-admins rather than erroring, so a manager's page just shows no bans.
create or replace function public.kf_banned_agent_ids()
returns setof uuid
language sql
stable
security definer
set search_path = public, auth, pg_temp
as $$
  select u.id
  from auth.users u
  where ( public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid )
    and u.banned_until is not null
    and u.banned_until > now();
$$;

revoke all on function public.kf_banned_agent_ids() from public, anon;
grant execute on function public.kf_banned_agent_ids() to authenticated;

-- 2. Lift the ban. Clears banned_until so the account can sign in again.
--    `approved` and `training_complete` are deliberately untouched — this only
--    undoes the auth-level block, not the approval or training gates.
--    If the agent is still archived, their profile is set back to active as
--    well (the recruiter-hq sync trigger picks that up on its own).
create or replace function public.unban_agent_user(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  if not ( public.wt_is_admin()
           or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid ) then
    raise exception 'Only the main admin can restore a login';
  end if;

  update auth.users
     set banned_until = null
   where id = target_user_id;

  update public.agent_profiles
     set status = 'active'
   where user_id = target_user_id
     and status is distinct from 'active';
end;
$$;

revoke all on function public.unban_agent_user(uuid) from public, anon;
grant execute on function public.unban_agent_user(uuid) to authenticated;
-- ============================================================================
