-- ============================================================================
-- daily_kpis — RLS lockdown (same pattern as policies)
-- ----------------------------------------------------------------------------
-- Closes the anon holes on the activity/KPI table: right now anyone with the
-- publishable key can read, insert, or update ANY rep's KPIs. After this:
--   • a rep reads/writes only their OWN KPIs;
--   • an upline manager can READ their downline's KPIs (Manager Dashboard /
--     Weekly Tracker); the admin reads everything;
--   • admin can also write any rep's KPIs (edit-on-behalf); the anon key can't
--     touch the table.
-- No safe feed needed — no regular-rep screen shows other reps' KPIs.
--
-- Run SECTION 1 now (additive, safe). Then the website code is switched to use
-- logins. Then run SECTION 2 (the lock). Same staging as the deals table.
-- ============================================================================


-- ############################################################################
-- SECTION 1 — RUN NOW (additive; grants login-based access; restricts nothing)
-- ############################################################################

-- Read: own, admin, or an upline manager of the KPI's owner.
drop policy if exists "KPI read own or team" on public.daily_kpis;
create policy "KPI read own or team" on public.daily_kpis
  for select to authenticated
  using ( auth.uid() = user_id
          or public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
          or public.kf_is_upline_of(user_id) );

-- Insert: own, or admin (edit-on-behalf).
drop policy if exists "KPI insert own or admin" on public.daily_kpis;
create policy "KPI insert own or admin" on public.daily_kpis
  for insert to authenticated
  with check ( auth.uid() = user_id
               or public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid );

-- Update: own, or admin.
drop policy if exists "KPI update own or admin" on public.daily_kpis;
create policy "KPI update own or admin" on public.daily_kpis
  for update to authenticated
  using ( auth.uid() = user_id
          or public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid )
  with check ( auth.uid() = user_id
               or public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid );


-- ############################################################################
-- SECTION 2 — DO NOT RUN YET. The lock. Run only AFTER the website code is
-- deployed + verified (all KPI reads/writes on the login token).
-- ############################################################################
--
-- begin;
-- drop policy if exists "Anon can read KPIs"   on public.daily_kpis;
-- drop policy if exists "Anyone can read KPIs" on public.daily_kpis;  -- public/true — also a hole
-- drop policy if exists "Anon can insert KPIs" on public.daily_kpis;
-- drop policy if exists "Anon can update KPIs" on public.daily_kpis;
-- commit;
-- ============================================================================
