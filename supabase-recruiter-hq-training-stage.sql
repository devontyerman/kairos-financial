-- ============================================================================
-- RECRUITER HQ: "Training" pipeline stage, comp-level guard, auto-promote,
-- and universal recruit coverage (every agent is reachable from Recruiter HQ).
-- ----------------------------------------------------------------------------
-- Run in the Supabase SQL Editor AFTER the earlier Recruiter HQ migrations.
-- Additive + idempotent.
--
-- STAGE MODEL (important): we ADD "Training" WITHOUT renumbering existing data.
--   0 Recruiting · 1 Studying · 2 Exam passed · 3 Contracting ·
--   4 Fully licensed (UNCHANGED) · 5 Training (NEW)
-- The pipeline DISPLAYS Training before Fully licensed (frontend ordering);
-- keeping "Fully licensed" = 4 means no data shift and nothing already live breaks.
-- ============================================================================

begin;

-- ── 1. Allow the new stage value (widen the check 0..4 → 0..5) ───────────────
alter table public.recruits drop constraint if exists recruits_stage_check;
alter table public.recruits
  add constraint recruits_stage_check check (stage between 0 and 5);

-- ── 2. Comp level is admin-only (true enforcement, mirrors kf_guard_approved) ─
create or replace function public.kf_guard_comp_level()
returns trigger language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if NEW.comp_level is distinct from OLD.comp_level then
    if not ( public.wt_is_admin()
             or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid ) then
      NEW.comp_level := OLD.comp_level;   -- silently ignore non-admin changes
    end if;
  end if;
  return NEW;
end;
$$;
drop trigger if exists kf_guard_comp_level_trg on public.agent_profiles;
create trigger kf_guard_comp_level_trg
  before update on public.agent_profiles
  for each row execute function public.kf_guard_comp_level();

-- ── 3. Auto-promote a trainee to Fully licensed when they finish training ────
-- Called by the training page (under the agent's own login) once they complete
-- all required videos. SECURITY DEFINER so it can move THEIR OWN linked recruit
-- even though the agent isn't that recruit's recruiter. Only ever moves a recruit
-- that is currently in Training (5) → Fully licensed (4); no-op otherwise.
create or replace function public.kf_promote_trainee_to_licensed()
returns void language sql security definer set search_path = public, pg_temp
as $$
  update public.recruits
     set stage = 4
   where linked_user_id = auth.uid() and stage = 5;
$$;
grant execute on function public.kf_promote_trainee_to_licensed() to authenticated;

-- ── 4. Every agent is a recruit: auto-create on signup when nothing matched ──
-- Extends the existing link-on-signup function. If a new agent_profiles row does
-- NOT match an existing recruit (by email/name), create a fresh linked recruit so
-- the agent is always reachable from Recruiter HQ (now that the Agency Agent
-- Profiles page is retired). Brand-new self-signups start at Recruiting (0).
create or replace function public.kf_link_recruit_on_signup()
returns trigger
language plpgsql security definer set search_path = public, auth
as $$
declare
  v_email     text;
  v_match_id  uuid;
  v_recruiter uuid;
  v_name_ct   int;
begin
  select lower(email) into v_email from auth.users where id = new.user_id;

  -- (a) Email match — strongest signal.
  if v_email is not null then
    select id, recruiter_user_id into v_match_id, v_recruiter
    from public.recruits
    where linked_user_id is null and lower(email) = v_email
    order by created_at asc limit 1;
  end if;

  -- (b) Fall back to full-name match, but only when unambiguous.
  if v_match_id is null and new.agent_name is not null then
    select count(*) into v_name_ct
    from public.recruits
    where linked_user_id is null and lower(full_name) = lower(new.agent_name);

    if v_name_ct = 1 then
      select id, recruiter_user_id into v_match_id, v_recruiter
      from public.recruits
      where linked_user_id is null and lower(full_name) = lower(new.agent_name)
      limit 1;
    elsif v_name_ct > 1 then
      update public.recruits set link_status = 'ambiguous'
      where linked_user_id is null and lower(full_name) = lower(new.agent_name);
    end if;
  end if;

  if v_match_id is not null then
    -- Link to the matched recruit + inherit recruiter as manager.
    update public.recruits
      set linked_user_id = new.user_id, link_status = 'auto',
          email = coalesce(email, v_email)
    where id = v_match_id;
    if v_recruiter is not null then
      update public.agent_profiles set manager_user_id = v_recruiter
      where user_id = new.user_id;
    end if;
  else
    -- No match: create a recruit so this agent is reachable from Recruiter HQ.
    insert into public.recruits
      (full_name, email, recruiter_user_id, stage, status, linked_user_id, link_status)
    values
      (new.agent_name, v_email, new.manager_user_id, 0, 'active', new.user_id, 'confirmed');
  end if;

  return null;
end;
$$;
-- (trigger already exists from the earlier migration; function is replaced in place)

commit;

-- ── 5. One-time backfill: create a recruit for any agent that lacks one ──────
-- Covers agents added since the first backfill. Existing agents are assumed
-- Fully licensed (4) like the original backfill; archived agents come in already
-- abandoned so they land in the Recruits "Archived" view, not the live pipeline.
insert into public.recruits
  (full_name, email, recruiter_user_id, stage, status, abandoned_at, linked_user_id, link_status, created_at)
select
  ap.agent_name, au.email, ap.manager_user_id, 4,
  case when ap.status = 'inactive' then 'abandoned' else 'active' end,
  case when ap.status = 'inactive' then now() else null end,
  ap.user_id, 'confirmed', now()
from public.agent_profiles ap
join auth.users au on au.id = ap.user_id
where ap.agent_name is not null
  and lower(coalesce(au.email,'')) <> 'dev@kairos-financial.com'
  and not exists (select 1 from public.recruits r where r.linked_user_id = ap.user_id);

-- ============================================================================
-- Verify:
--   select stage, status, count(*) from public.recruits group by 1,2 order by 1;
--   -- agents with no recruit (should be 0, excluding the owner):
--   select count(*) from public.agent_profiles ap
--     join auth.users au on au.id=ap.user_id
--     where lower(coalesce(au.email,''))<>'dev@kairos-financial.com'
--       and not exists (select 1 from public.recruits r where r.linked_user_id=ap.user_id);
-- ============================================================================
