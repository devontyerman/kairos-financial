-- ─────────────────────────────────────────────────────────────────────────
-- Profile location fields (city / state / time zone)
--
-- Adds city/state/timezone to agent_profiles so an agent can edit them on
-- their own Profile page (they can read/write their own agent_profiles row,
-- but NOT their recruits row under RLS). A SECURITY DEFINER trigger mirrors
-- the values into the linked recruit row so managers see them in Recruiter HQ,
-- exactly like the other agent_profiles → recruits sync triggers.
--
-- Safe to run more than once.
-- ─────────────────────────────────────────────────────────────────────────

alter table public.agent_profiles
  add column if not exists city     text,
  add column if not exists state    text,
  add column if not exists timezone text;

-- Mirror agent-edited location into the linked recruit row. SECURITY DEFINER so
-- it can update a recruit the agent doesn't "own" (they aren't the recruiter).
create or replace function public.kf_sync_profile_location()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if NEW.city     is distinct from OLD.city
     or NEW.state    is distinct from OLD.state
     or NEW.timezone is distinct from OLD.timezone then
    update public.recruits
       set city     = NEW.city,
           state    = NEW.state,
           timezone = coalesce(NEW.timezone, timezone)
     where linked_user_id = NEW.user_id;
  end if;
  return NEW;
end;
$$;

drop trigger if exists kf_sync_profile_location_trg on public.agent_profiles;
create trigger kf_sync_profile_location_trg
  after update on public.agent_profiles
  for each row execute function public.kf_sync_profile_location();
