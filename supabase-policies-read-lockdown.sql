-- ============================================================================
-- Policies — READ lockdown (RLS Phase 3)
-- ----------------------------------------------------------------------------
-- Goal: a sales rep can no longer read another rep's RAW deal data (client
-- names, phone numbers, policy numbers) — not even by pulling the key from the
-- page and hitting the API directly. Meanwhile:
--   • the leaderboard & weekly tracker keep working, via a safe feed that
--     exposes only rep + premium + dates (NO client PII);
--   • a manager (flagged in the hierarchy) can read their downline's deals;
--   • the admin can read everything.
--
-- Run order (each section is safe on its own):
--   SECTION 1 + 2 — additive, RUN FIRST (done). Create the safe feed, the
--     hierarchy helper, and the admin/upline read grant. Nothing is restricted
--     yet, so the site behaves the same after running them.
--   [ website code is then switched to read via the safe feed / login token ]
--   SECTION 3 — the actual read lock. RUN LAST, only after the code is deployed
--     and verified, so the leaderboard/team screens never go blank.
-- ============================================================================


-- ############################################################################
-- SECTION 1 — RUN NOW (additive; done)
-- ############################################################################

-- 1a. Safe leaderboard/aggregate feed: only non-PII columns; login-only.
create or replace view public.policies_leaderboard as
  select user_id, sales_rep, annual_premium, policy_date, created_at, status
  from public.policies;
revoke all on public.policies_leaderboard from anon, authenticated, public;
grant select on public.policies_leaderboard to authenticated;

-- 1b. Hierarchy helper: is the caller an upline manager of this deal's owner?
create or replace function public.kf_is_upline_of(target uuid)
returns boolean
language sql stable security definer set search_path = public, pg_temp
as $$
  with recursive chain as (
    select user_id, manager_user_id from public.agent_profiles where user_id = target
    union all
    select ap.user_id, ap.manager_user_id
    from public.agent_profiles ap join chain c on ap.user_id = c.manager_user_id
  )
  select
    exists (select 1 from chain where chain.manager_user_id = auth.uid())
    and exists (select 1 from public.agent_profiles v
                where v.user_id = auth.uid() and v.is_manager = true);
$$;
grant execute on function public.kf_is_upline_of(uuid) to authenticated;


-- ############################################################################
-- SECTION 2 — RUN NOW (additive; done). Lets admins + upline managers read
-- other agents' deals via their login. Adds access only; restricts nothing.
-- ############################################################################

drop policy if exists "Admin and upline read" on public.policies;
create policy "Admin and upline read" on public.policies
  for select to authenticated
  using ( public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
          or public.kf_is_upline_of(user_id) );


-- ############################################################################
-- SECTION 3 — the read lock. APPLIED after the website code was deployed and
-- verified (leaderboard via feed; all deal reads via login; admin screens
-- confirmed working; exposed key confirmed unable to read raw deals).
-- ############################################################################

begin;
-- Remove the anonymous "read everything" hole. After this, reading a raw deal
-- requires a login, and RLS returns: own rows for a rep, downline for a
-- manager, everything for the admin. The leaderboard reads the safe feed.
drop policy if exists "Allow reads" on public.policies;

-- Tidy: strip the default PUBLIC execute on the helper so only logged-in users
-- can call it (it only ever returns false for anon anyway).
revoke execute on function public.kf_is_upline_of(uuid) from public, anon;
commit;
-- ============================================================================
