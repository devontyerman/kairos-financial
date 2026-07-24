-- ============================================================================
-- RECRUITER HQ — schema + RLS + linking + backfill
-- ----------------------------------------------------------------------------
-- Powers the Recruiter HQ page in the Sales Hub. Manages the recruiting
-- pipeline from initial prospect → onboarding → licensing, BEFORE a recruit
-- ever has a Sales Hub account, then auto-links to their account once created.
--
-- Design principles (per project conventions):
--   • Reuses existing infrastructure — hierarchy lives in agent_profiles
--     (manager_user_id / is_manager), admin gating via wt_is_admin(), downline
--     visibility via kf_is_upline_of(). No hierarchy logic is duplicated.
--   • Recruiting-specific data lives in NEW tables prefixed `recruit*`.
--   • Sales-performance data is NEVER copied — Recruiter HQ reads it live from
--     `policies` / `agent_profiles` once a recruit is linked to an account.
--   • Additive + idempotent: safe to run more than once, breaks nothing existing.
--
-- Visibility model (matches the rest of the site):
--   • Admin (wt_is_admin() / owner user_id)      → sees ALL recruits.
--   • Manager (is_manager = true)                → sees recruits they brought in
--     PLUS every recruit brought in by anyone in their downline
--     (kf_is_upline_of(recruiter_user_id)).
--   • Regular agent                              → no access (UI hides the page).
--
-- Run this in the Supabase SQL Editor.
-- ============================================================================

begin;

-- ── 1. RECRUITS ─────────────────────────────────────────────────────────────
-- One row per person in the recruiting pipeline. May exist long before any
-- Sales Hub account (linked_user_id stays NULL until they sign up).
create table if not exists public.recruits (
  id                uuid primary key default gen_random_uuid(),
  full_name         text not null,
  email             text,
  phone             text,
  city              text,
  state             text,
  timezone          text,
  -- Who brought them in. Points at an agent's user_id (their upline in the org).
  recruiter_user_id uuid references auth.users(id) on delete set null,
  -- Pipeline stage, 0-based index into the Recruiter HQ stage list:
  --   0 Recruiting · 1 Studying · 2 Exam passed · 3 Contracting · 4 Fully licensed
  stage             smallint not null default 0 check (stage between 0 and 4),
  stage_entered_at  timestamptz not null default now(),
  exam_date         date,
  -- 'active' = live in the pipeline; 'abandoned' = parked but kept for re-apply.
  status            text not null default 'active' check (status in ('active','abandoned')),
  abandoned_at      timestamptz,
  -- Goals (free text, shown on the recruit profile).
  goal_90           text,
  goal_year1        text,
  goal_long_term    text,
  their_why         text,
  -- Link to a Sales Hub account, once one exists. NULL = pre-account recruit.
  linked_user_id    uuid references auth.users(id) on delete set null,
  --   unlinked  : no account yet
  --   auto      : linked automatically (email or unambiguous name match)
  --   confirmed : an admin/manager confirmed the link (or it was backfilled)
  --   ambiguous : multiple unlinked recruits share this name — needs a manual pick
  link_status       text not null default 'unlinked'
                    check (link_status in ('unlinked','auto','confirmed','ambiguous')),
  created_by        uuid references auth.users(id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists recruits_recruiter_idx on public.recruits (recruiter_user_id);
create index if not exists recruits_linked_idx    on public.recruits (linked_user_id);
create index if not exists recruits_status_idx    on public.recruits (status);
create index if not exists recruits_email_idx     on public.recruits (lower(email));
create index if not exists recruits_name_idx      on public.recruits (lower(full_name));

-- ── 2. RECRUIT NOTES ────────────────────────────────────────────────────────
create table if not exists public.recruit_notes (
  id              uuid primary key default gen_random_uuid(),
  recruit_id      uuid not null references public.recruits(id) on delete cascade,
  author_user_id  uuid references auth.users(id) on delete set null,
  body            text not null,
  created_at      timestamptz not null default now()
);
create index if not exists recruit_notes_recruit_idx on public.recruit_notes (recruit_id);

-- ── 3. RECRUIT STAGE EVENTS (timeline) ──────────────────────────────────────
-- Auto-written whenever a recruit's stage or status changes (see trigger below).
create table if not exists public.recruit_stage_events (
  id           uuid primary key default gen_random_uuid(),
  recruit_id   uuid not null references public.recruits(id) on delete cascade,
  stage        smallint not null,
  status       text not null,
  changed_by   uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now()
);
create index if not exists recruit_stage_events_recruit_idx on public.recruit_stage_events (recruit_id);

-- ── 4. TRIGGERS ─────────────────────────────────────────────────────────────

-- 4a. Touch updated_at on every recruit UPDATE, and re-stamp stage_entered_at
--     whenever the stage or status actually changes.
create or replace function public.recruits_before_update()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  if (new.stage is distinct from old.stage) or (new.status is distinct from old.status) then
    new.stage_entered_at := now();
  end if;
  return new;
end;
$$;
drop trigger if exists recruits_before_update_trg on public.recruits;
create trigger recruits_before_update_trg
  before update on public.recruits
  for each row execute function public.recruits_before_update();

-- 4b. Log a stage-history event on insert, and on any stage/status change.
--     AFTER trigger so the parent recruit row already exists (FK-safe).
create or replace function public.recruits_log_stage_event()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if (tg_op = 'INSERT') then
    insert into public.recruit_stage_events (recruit_id, stage, status, changed_by)
    values (new.id, new.stage, new.status, auth.uid());
  elsif (tg_op = 'UPDATE') and
        ((new.stage is distinct from old.stage) or (new.status is distinct from old.status)) then
    insert into public.recruit_stage_events (recruit_id, stage, status, changed_by)
    values (new.id, new.stage, new.status, auth.uid());
  end if;
  return null;
end;
$$;
drop trigger if exists recruits_log_stage_event_trg on public.recruits;
create trigger recruits_log_stage_event_trg
  after insert or update on public.recruits
  for each row execute function public.recruits_log_stage_event();

-- ── 5. ROW-LEVEL SECURITY ───────────────────────────────────────────────────
alter table public.recruits             enable row level security;
alter table public.recruit_notes        enable row level security;
alter table public.recruit_stage_events enable row level security;

-- Helper predicate, inlined per policy: a caller may see a recruit when they are
-- the admin, the recruiter themselves, or an upline manager of the recruiter.
-- (kf_is_upline_of already requires the caller to be is_manager = true.)

-- RECRUITS -------------------------------------------------------------------
drop policy if exists "recruits_select" on public.recruits;
create policy "recruits_select" on public.recruits
  for select to authenticated
  using ( public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
          or recruiter_user_id = auth.uid()
          or public.kf_is_upline_of(recruiter_user_id) );

drop policy if exists "recruits_insert" on public.recruits;
create policy "recruits_insert" on public.recruits
  for insert to authenticated
  with check ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
               or recruiter_user_id = auth.uid()
               or public.kf_is_upline_of(recruiter_user_id) );

drop policy if exists "recruits_update" on public.recruits;
create policy "recruits_update" on public.recruits
  for update to authenticated
  using      ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
               or recruiter_user_id = auth.uid()
               or public.kf_is_upline_of(recruiter_user_id) )
  with check ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
               or recruiter_user_id = auth.uid()
               or public.kf_is_upline_of(recruiter_user_id) );

drop policy if exists "recruits_delete" on public.recruits;
create policy "recruits_delete" on public.recruits
  for delete to authenticated
  using ( public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
          or recruiter_user_id = auth.uid()
          or public.kf_is_upline_of(recruiter_user_id) );

-- NOTES + STAGE EVENTS: inherit visibility from the parent recruit. -----------
drop policy if exists "recruit_notes_select" on public.recruit_notes;
create policy "recruit_notes_select" on public.recruit_notes
  for select to authenticated
  using ( exists (select 1 from public.recruits r
                  where r.id = recruit_id
                    and ( public.wt_is_admin()
                          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
                          or r.recruiter_user_id = auth.uid()
                          or public.kf_is_upline_of(r.recruiter_user_id) )) );

drop policy if exists "recruit_notes_insert" on public.recruit_notes;
create policy "recruit_notes_insert" on public.recruit_notes
  for insert to authenticated
  with check ( author_user_id = auth.uid()
               and exists (select 1 from public.recruits r
                  where r.id = recruit_id
                    and ( public.wt_is_admin()
                          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
                          or r.recruiter_user_id = auth.uid()
                          or public.kf_is_upline_of(r.recruiter_user_id) )) );

drop policy if exists "recruit_notes_delete" on public.recruit_notes;
create policy "recruit_notes_delete" on public.recruit_notes
  for delete to authenticated
  using ( public.wt_is_admin()
          or author_user_id = auth.uid() );

drop policy if exists "recruit_stage_events_select" on public.recruit_stage_events;
create policy "recruit_stage_events_select" on public.recruit_stage_events
  for select to authenticated
  using ( exists (select 1 from public.recruits r
                  where r.id = recruit_id
                    and ( public.wt_is_admin()
                          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
                          or r.recruiter_user_id = auth.uid()
                          or public.kf_is_upline_of(r.recruiter_user_id) )) );

-- Stage events are written by the SECURITY DEFINER trigger, not by clients.

-- ── 6. AUTO-LINK ON SIGNUP ──────────────────────────────────────────────────
-- When a new agent_profiles row is created (signup), try to link it to an
-- existing unlinked recruit: match on email first, then unambiguous full name.
-- On a successful link, set the new agent's manager to their recruiter so the
-- org chart reflects who recruited whom (overrides the owner-default trigger;
-- a later manual drag-reparent still wins). Ambiguous name matches are flagged
-- for an admin to resolve from the recruit profile — never auto-linked.
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
    order by created_at asc
    limit 1;
  end if;

  -- (b) Fall back to full-name match, but only when it is unambiguous.
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
      update public.recruits
      set link_status = 'ambiguous'
      where linked_user_id is null and lower(full_name) = lower(new.agent_name);
    end if;
  end if;

  if v_match_id is not null then
    update public.recruits
    set linked_user_id = new.user_id,
        link_status    = 'auto',
        -- If they just made an account they are at least contracting-bound;
        -- do not downgrade an already-higher stage.
        email          = coalesce(email, v_email)
    where id = v_match_id;

    -- Recruiter becomes the new agent's manager (per project decision).
    if v_recruiter is not null then
      update public.agent_profiles
      set manager_user_id = v_recruiter
      where user_id = new.user_id;
    end if;
  end if;

  return null;
end;
$$;

drop trigger if exists kf_link_recruit_on_signup_trg on public.agent_profiles;
create trigger kf_link_recruit_on_signup_trg
  after insert on public.agent_profiles
  for each row execute function public.kf_link_recruit_on_signup();

commit;

-- ── 7. BACKFILL EXISTING AGENTS ─────────────────────────────────────────────
-- Seed Recruiter HQ with every current agent as a Fully-licensed (stage 4),
-- account-linked recruit, assigned to their upline manager as the recruiter.
-- The org owner is excluded (they were not recruited). Idempotent: an agent
-- already present as a linked recruit is skipped. Re-runnable safely.
insert into public.recruits
  (full_name, email, recruiter_user_id, stage, status, linked_user_id, link_status, created_at)
select
  ap.agent_name,
  au.email,
  ap.manager_user_id,
  4,                 -- Fully licensed (edit any that aren't, from the profile)
  'active',
  ap.user_id,
  'confirmed',
  now()
from public.agent_profiles ap
join auth.users au on au.id = ap.user_id
where ap.agent_name is not null
  and lower(coalesce(au.email,'')) <> 'dev@kairos-financial.com'
  and not exists (
    select 1 from public.recruits r where r.linked_user_id = ap.user_id
  );

-- ============================================================================
-- DONE. After running this in the Supabase SQL editor:
--   1. Reload the Sales Hub as an admin/manager — "Recruiter HQ" appears in the
--      left nav.
--   2. Every existing agent shows up under "Fully licensed", credited to their
--      recruiter (their current upline manager).
--   3. New signups auto-link to a matching recruit and inherit their recruiter
--      as manager; ambiguous name matches show a "Confirm link" prompt.
--
-- Verify (read-only):
--   select stage, status, count(*) from public.recruits group by 1,2 order by 1;
--   select policyname, cmd, roles from pg_policies
--     where tablename in ('recruits','recruit_notes','recruit_stage_events')
--     order by tablename, cmd;
-- ============================================================================
