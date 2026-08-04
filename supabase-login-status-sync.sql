-- ============================================================================
-- Login follows status
-- ----------------------------------------------------------------------------
-- Removing an agent has always done two things: hide them
-- (agent_profiles.status = 'inactive') and switch off their login
-- (auth.users.banned_until). archive_agent_user / unarchive_agent_user both did
-- both halves correctly — but they were not the only thing moving `status`.
--
-- kf_sync_recruit_status_to_agent (supabase-recruiter-hq-sync.sql) flips an
-- agent between active and inactive whenever their RECRUIT record changes, and
-- its own comment admits it "does not ban the auth login". So:
--
--   * restore a recruit to the pipeline → profile active, login still blocked
--     (this is what stranded Brian Champion — active everywhere on screen, and
--      "User is banned" at the login box, with nothing in the UI to explain it)
--   * abandon a recruit → profile inactive, login still WORKING — removed from
--     every screen while their password still let them in
--
-- Rather than patch that one trigger, this makes the login follow the status
-- column no matter what moves it: the buttons, the recruit sync, a hand edit in
-- the Supabase table editor, or anything added later.
--
-- RUN IN PRODUCTION 2026-08-03. Safe to run more than once.
-- ============================================================================

create or replace function public.kf_sync_login_to_status()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
begin
  if NEW.status is distinct from OLD.status then
    if NEW.status = 'inactive' then
      update auth.users
         set banned_until = now() + interval '100 years'
       where id = NEW.user_id;
      -- Boot any live session so it takes effect now, not at next login.
      delete from auth.sessions       where user_id = NEW.user_id;
      delete from auth.refresh_tokens where user_id::text = NEW.user_id::text;
    elsif NEW.status = 'active' then
      update auth.users
         set banned_until = null
       where id = NEW.user_id;
    end if;
  end if;
  return null;
end;
$$;

drop trigger if exists kf_sync_login_to_status_trg on public.agent_profiles;
create trigger kf_sync_login_to_status_trg
  after update of status on public.agent_profiles
  for each row execute function public.kf_sync_login_to_status();


-- ── One-time sweep: correct everyone already mismatched ─────────────────────
-- Ran 2026-08-03. Re-running is harmless (both statements are no-ops once the
-- trigger above is in place and everything already agrees).

-- Hidden but still able to log in → block them.
update auth.users u
set banned_until = now() + interval '100 years'
from public.agent_profiles p
where p.user_id = u.id
  and p.status = 'inactive'
  and (u.banned_until is null or u.banned_until <= now());

-- On the roster but blocked → let them in.
update auth.users u
set banned_until = null
from public.agent_profiles p
where p.user_id = u.id
  and p.status is distinct from 'inactive'
  and u.banned_until is not null
  and u.banned_until > now();


-- ── Check: should return zero rows ──────────────────────────────────────────
-- select p.agent_name, p.status,
--        case when u.banned_until is not null and u.banned_until > now()
--             then 'blocked' else 'can log in' end as login
-- from public.agent_profiles p
-- join auth.users u on u.id = p.user_id
-- where (p.status = 'inactive')
--    <> (u.banned_until is not null and u.banned_until > now())
-- order by p.agent_name;
-- ============================================================================
