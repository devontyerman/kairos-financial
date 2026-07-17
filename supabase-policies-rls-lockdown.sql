-- ============================================================================
-- Policies — WRITE lockdown (RLS Phase 2)
-- Run this in the Supabase SQL Editor. Safe to run more than once.
-- ----------------------------------------------------------------------------
-- Removes the anonymous "allow anything" WRITE rules on the deals table, so a
-- rep — or anyone who lifts the publishable key out of the page source — can no
-- longer insert, edit, or delete deals they don't own. This is what closes the
-- hole that let David Krusing's deals be deleted.
--
-- After this migration, on public.policies:
--   • A signed-in rep can INSERT / UPDATE / DELETE only their OWN deals
--     (the existing "Agent * own" policies, keyed on auth.uid() = user_id).
--   • The admin can write ANY deal (Book of Business management, agent removal).
--   • The anon / publishable key can no longer write at all.
--
-- READS are intentionally LEFT UNCHANGED here — the "Allow reads" anon policy
-- stays, so the leaderboard and every other screen keep working exactly as now.
-- Locking reads (and adding manager/downline visibility + the safe leaderboard
-- feed) is Phase 3, done separately so we can verify the leaderboard first.
--
-- Prereqs already in place (confirmed from pg_policies):
--   • RLS is enabled on public.policies.
--   • "Agent insert own / update own / delete own" (role: authenticated) exist.
--   • public.wt_is_admin() exists (email allowlist → dev@kairos-financial.com),
--     granted to authenticated.
-- This migration only removes the anon write holes and adds the admin override.
-- ============================================================================

begin;

-- 1. Remove the anonymous WRITE holes (USING/CHECK = true, role = anon).
--    These are what let the exposed key insert/edit/delete ANY deal.
--    ("Allow reads" is deliberately NOT dropped here — that's Phase 3.)
drop policy if exists "Allow inserts" on public.policies;
drop policy if exists "Allow updates" on public.policies;
drop policy if exists "Allow deletes" on public.policies;

-- 2. Admin override — the owner/admin can write ANY deal. Identified by the
--    wt_admins email allowlist (dev@kairos-financial.com) OR the known admin
--    user_id, so an email mismatch can never lock the admin out of their own
--    data. (agent_profiles already uses this same admin user_id in its policy.)
drop policy if exists "Admin insert any" on public.policies;
create policy "Admin insert any" on public.policies
  for insert to authenticated
  with check ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid );

drop policy if exists "Admin update any" on public.policies;
create policy "Admin update any" on public.policies
  for update to authenticated
  using      ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid )
  with check ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid );

drop policy if exists "Admin delete any" on public.policies;
create policy "Admin delete any" on public.policies
  for delete to authenticated
  using ( public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid );

commit;

-- ----------------------------------------------------------------------------
-- Verify (read-only). After running, the anon write policies should be GONE and
-- only these should remain for writes on `policies`:
--   INSERT  : "Agent insert own" (authenticated), "Admin insert any", plus the
--             harmless "users can insert their own policies" (public, own-only)
--   UPDATE  : "Agent update own", "Admin update any"
--   DELETE  : "Agent delete own", "Admin delete any"
--   SELECT  : unchanged — "Allow reads" (anon) still present until Phase 3
--
-- select policyname, cmd, roles from pg_policies
-- where tablename = 'policies' order by cmd, policyname;
-- ============================================================================
