-- ============================================================================
-- agent_profiles — RLS lockdown (the "user list")
-- ----------------------------------------------------------------------------
-- Closes the hole where anyone with the publishable key can read EVERY agent's
-- comp level, goals, Discord ID, and licenses. After this:
--   • Names + org hierarchy stay readable to all logins via a safe "roster"
--     view (needed for the leaderboard names, dropdowns, org chart).
--   • The SENSITIVE columns (comp_level, annual_goal, discord_id,
--     state_licenses, carrier_numbers) on the base table are readable only for
--     your OWN profile, your downline (managers), or everything (admin).
--   • The anon key can no longer read the base table.
--
-- PAY MATH IS SAFE: pay/pipeline calcs read the signed-in rep's OWN comp_level
-- (auth.uid() = user_id), which the "Users read own profile" policy always
-- allows. No calc ever needs another agent's comp.
--
-- Writes are unchanged — agent_profiles already had NO anon write policies
-- (insert/update were already own-or-admin only).
--
-- Run SECTION 1 now (additive). Then the site code is switched to read names
-- via the roster view and sensitive columns via the login token. Then run
-- SECTION 2 (the lock).
-- ============================================================================


-- ############################################################################
-- SECTION 1 — RUN NOW (additive; safe; changes nothing yet)
-- ############################################################################

-- 1a. Safe roster: names + hierarchy + status only. NO comp/goals/discord/
--     licenses. Login-only. This is what the "all agents" name/dropdown/org
--     reads use once the base table is locked.
create or replace view public.agent_roster as
  select user_id, agent_name, is_manager, manager_user_id, status, training_complete
  from public.agent_profiles;
revoke all on public.agent_roster from anon, authenticated, public;
grant select on public.agent_roster to authenticated;

-- 1b. Let admins + upline managers read full profiles (comp etc.) of the agents
--     they're allowed to see. "Users read own profile" already covers own.
drop policy if exists "Admin and upline read profiles" on public.agent_profiles;
create policy "Admin and upline read profiles" on public.agent_profiles
  for select to authenticated
  using ( public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
          or public.kf_is_upline_of(user_id) );


-- ############################################################################
-- SECTION 2 — the lock. APPLIED after the code was deployed + verified.
-- ############################################################################

begin;
drop policy if exists "Anon read all profiles" on public.agent_profiles;
commit;
-- ============================================================================
