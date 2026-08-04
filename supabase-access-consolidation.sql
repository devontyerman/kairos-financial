-- ============================================================================
-- Access consolidation
-- ----------------------------------------------------------------------------
-- One way in (invite), one way out (Remove agent). This migration:
--   PART A — auto-approves anyone whose email matches a recruit record, so the
--            Approve button is no longer something you press by hand.
--   PART B — drops the 10-day profile-completion deadline (feature deleted).
--
-- Part A is safe to run now. Part B DESTROYS the stored deadlines — run it only
-- once you're happy the site works without that feature.
--
-- Safe to run more than once.
-- ============================================================================


-- ── PART A: approve invited agents automatically ────────────────────────────
-- New agent_profiles rows default to approved = false. If the new account's
-- email matches a recruit in Recruiting HQ, that's someone we invited, so they
-- go straight in. No match = they turn up at the waiting screen and an admin
-- decides ("Let them in" on their profile).
--
-- Email only, on purpose: a name match is not proof of an invite.
create or replace function public.kf_autoapprove_invited()
returns trigger
language plpgsql
security definer
set search_path = public, auth, pg_temp
as $$
declare
  v_email text;
begin
  select lower(email) into v_email from auth.users where id = NEW.user_id;

  if v_email is not null and exists (
    select 1 from public.recruits where lower(email) = v_email
  ) then
    NEW.approved := true;
  end if;

  return NEW;
end;
$$;

drop trigger if exists kf_autoapprove_invited_trg on public.agent_profiles;
create trigger kf_autoapprove_invited_trg
  before insert on public.agent_profiles
  for each row execute function public.kf_autoapprove_invited();

-- Catch up anyone already sitting at the waiting screen who we did invite.
update public.agent_profiles p
set approved = true
where p.approved = false
  and exists (
    select 1
    from auth.users u
    join public.recruits r on lower(r.email) = lower(u.email)
    where u.id = p.user_id
  );


-- ── PART B: delete the 10-day profile deadline ──────────────────────────────
-- Run this only after confirming the site is fine without it. Dropping the
-- column deletes every stored deadline permanently.
--
--   drop trigger if exists kf_guard_profile_due_trg on public.agent_profiles;
--   drop function if exists public.kf_guard_profile_due();
--   alter table public.agent_profiles drop column if exists profile_due_at;
--
-- Uncomment the three lines above (remove the leading "-- ") to run them.
-- ============================================================================
