-- ============================================================================
-- Signup approval gate
-- ----------------------------------------------------------------------------
-- New accounts start unapproved and are blocked at an "awaiting approval"
-- screen in the Sales Hub until an admin (or an upline manager) approves them.
-- All existing agents are grandfathered in so nobody active loses access.
--
-- Safe to run more than once.
-- ============================================================================

-- 1. The approval flag. New rows default to false (unapproved).
alter table public.agent_profiles
  add column if not exists approved boolean not null default false;

-- 2. Grandfather every CURRENT agent so no active user is locked out.
update public.agent_profiles set approved = true where approved is not true;

-- 3. GUARD: only an admin or an upline manager may change `approved`. Without
--    this, a pending user could PATCH their own row (the "update own profile"
--    policy) and self-approve, bypassing the gate. This BEFORE UPDATE trigger
--    reverts any `approved` change made by anyone else back to its old value.
create or replace function public.kf_guard_approved()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if NEW.approved is distinct from OLD.approved then
    if not ( public.wt_is_admin()
             or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
             or public.kf_is_upline_of(NEW.user_id) ) then
      NEW.approved := OLD.approved;   -- silently ignore self-approval attempts
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists kf_guard_approved_trg on public.agent_profiles;
create trigger kf_guard_approved_trg
  before update on public.agent_profiles
  for each row execute function public.kf_guard_approved();
-- ============================================================================
