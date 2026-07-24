-- ============================================================================
-- RECRUITER HQ ↔ AGENCY sync: archive / abandon / delete stay in lockstep
-- ----------------------------------------------------------------------------
-- Keeps a recruit and its linked Sales Hub agent in the same state, no matter
-- which side the change is made on:
--
--   • Archive an agent (agency hierarchy / Agent Profiles → status='inactive')
--       → their linked recruit is ABANDONED (hidden from Recruits + Pipeline).
--   • Unarchive an agent (status back to 'active')
--       → their linked recruit is RESTORED to the pipeline.
--   • Abandon a recruit (Recruiter HQ)
--       → their linked agent is ARCHIVED (status='inactive', hidden from the
--         hierarchy + Agent Profiles). Restore reverses it.
--   • Delete an agent (agency hard-delete)
--       → their recruit row is deleted too (FK cascade + safety trigger).
--   • Deleting FROM the recruiting page is disabled in the UI — recruits are
--     only ever abandoned there, never hard-deleted.
--
-- Loop-safe: each side only writes the other when it actually differs, so the
-- mirrored write is a no-op and no recursion occurs.
--
-- Additive + idempotent. Run in the Supabase SQL Editor AFTER
-- supabase-recruiter-hq-migration.sql.
-- ============================================================================

begin;

-- ── 1. Deleting the linked account deletes the recruit (was: set null) ───────
alter table public.recruits
  drop constraint if exists recruits_linked_user_id_fkey;
alter table public.recruits
  add  constraint recruits_linked_user_id_fkey
       foreign key (linked_user_id) references auth.users(id) on delete cascade;

-- ── 2. Agent archived/unarchived  →  mirror onto the linked recruit ──────────
create or replace function public.kf_sync_agent_status_to_recruit()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if NEW.status is distinct from OLD.status then
    if NEW.status = 'inactive' then
      update public.recruits
        set status = 'abandoned', abandoned_at = coalesce(abandoned_at, now())
        where linked_user_id = NEW.user_id and status <> 'abandoned';
    elsif NEW.status = 'active' then
      update public.recruits
        set status = 'active', abandoned_at = null
        where linked_user_id = NEW.user_id and status <> 'active';
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists kf_sync_agent_status_to_recruit_trg on public.agent_profiles;
create trigger kf_sync_agent_status_to_recruit_trg
  after update of status on public.agent_profiles
  for each row execute function public.kf_sync_agent_status_to_recruit();

-- ── 3. Recruit abandoned/restored  →  mirror onto the linked agent ───────────
--    (Hides/shows them in the agency hierarchy + Agent Profiles. This mirrors
--     the STATUS only; it does not ban the auth login — use the agency
--     delete/archive flow if a login ban is also required.)
create or replace function public.kf_sync_recruit_status_to_agent()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if NEW.status is distinct from OLD.status and NEW.linked_user_id is not null then
    if NEW.status = 'abandoned' then
      update public.agent_profiles
        set status = 'inactive'
        where user_id = NEW.linked_user_id and status is distinct from 'inactive';
    elsif NEW.status = 'active' then
      update public.agent_profiles
        set status = 'active'
        where user_id = NEW.linked_user_id and status is distinct from 'active';
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists kf_sync_recruit_status_to_agent_trg on public.recruits;
create trigger kf_sync_recruit_status_to_agent_trg
  after update of status on public.recruits
  for each row execute function public.kf_sync_recruit_status_to_agent();

-- ── 4. Safety net: if an agent_profiles row is deleted directly (not via an
--    auth.users cascade), delete the linked recruit too. ───────────────────────
create or replace function public.kf_delete_recruit_with_agent()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  delete from public.recruits where linked_user_id = OLD.user_id;
  return OLD;
end;
$$;

drop trigger if exists kf_delete_recruit_with_agent_trg on public.agent_profiles;
create trigger kf_delete_recruit_with_agent_trg
  after delete on public.agent_profiles
  for each row execute function public.kf_delete_recruit_with_agent();

commit;

-- ── 5. One-time backfill: hide recruits whose agent is already archived ──────
update public.recruits r
  set status = 'abandoned', abandoned_at = coalesce(abandoned_at, now())
from public.agent_profiles ap
where r.linked_user_id = ap.user_id
  and ap.status = 'inactive'
  and r.status <> 'abandoned';

-- ============================================================================
-- Verify:
--   -- archived agents whose recruit is NOT abandoned (should be 0):
--   select count(*) from public.recruits r join public.agent_profiles ap
--     on ap.user_id = r.linked_user_id
--     where ap.status='inactive' and r.status<>'abandoned';
-- ============================================================================
