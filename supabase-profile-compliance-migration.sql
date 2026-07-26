-- ============================================================================
-- Profile completion deadline
-- ----------------------------------------------------------------------------
-- Agents who are missing a profile photo, state license numbers, or carrier
-- writing numbers are nudged to complete them, with a 10-day countdown. On the
-- first login where they're incomplete, the app stamps `profile_due_at` = now
-- + 10 days. Warnings escalate, and once the due date passes the Sales Hub is
-- locked (except the Profile page) until they finish.
--
-- The guard trigger stops an agent from gaming the clock: they can only set it
-- once (null -> a value at most ~10 days out) and can't push it further out.
-- Admins / upline managers can adjust it (e.g. to grant an extension).
--
-- Safe to run more than once.
-- ============================================================================

alter table public.agent_profiles
  add column if not exists profile_due_at timestamptz;

create or replace function public.kf_guard_profile_due()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if NEW.profile_due_at is distinct from OLD.profile_due_at then
    if not ( public.wt_is_admin()
             or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
             or public.kf_is_upline_of(NEW.user_id) ) then
      if OLD.profile_due_at is not null then
        NEW.profile_due_at := OLD.profile_due_at;                 -- can't change once set
      elsif NEW.profile_due_at > now() + interval '10 days 30 minutes' then
        NEW.profile_due_at := now() + interval '10 days';         -- cap the initial set
      end if;
    end if;
  end if;
  return NEW;
end;
$$;

drop trigger if exists kf_guard_profile_due_trg on public.agent_profiles;
create trigger kf_guard_profile_due_trg
  before update on public.agent_profiles
  for each row execute function public.kf_guard_profile_due();
-- ============================================================================
