-- ============================================================================
-- Agent Onboarding
-- ----------------------------------------------------------------------------
-- Powers the invite-only, guided onboarding flow a NEW agent walks through the
-- first time they log in (welcome video → account → profile → photo → goals →
-- 90-day commitment → license/NPN → states → E&O → Discord → CRM → meetings →
-- training → done). On completion the account auto-activates.
--
-- Design goal: ONE source of truth. The agent's personal info + goals live on
-- their `recruits` row (the same row the Recruiter HQ profile shows), so what
-- the agent types during onboarding is exactly what the recruiter sees. Account
-- and licensing fields live on `agent_profiles`.
--
-- EXISTING agents are grandfathered (onboarding_completed = true) so they never
-- see the flow. Only brand-new invited accounts go through it.
--
-- Safe to run more than once.
-- ============================================================================

-- ────────────────────────────────────────────────────────────────────────────
-- 1. recruits: the extra profile + structured-goal fields the flow collects.
--    (city, state, phone, email, their_why, goal_90/goal_year1/goal_long_term
--     already exist — we reuse them and mirror readable summaries into them.)
-- ────────────────────────────────────────────────────────────────────────────
alter table public.recruits
  add column if not exists zip            text,
  add column if not exists resident_state text,
  add column if not exists dob            date,
  add column if not exists st_goals       jsonb,   -- 3 short-term goals (first 90 days)
  add column if not exists lt_goals       jsonb,   -- 3 long-term goals (first year)
  add column if not exists vision         text,    -- where they see themselves in 3–5 years
  add column if not exists skills         jsonb,   -- skills/habits to improve
  add column if not exists give_ups       jsonb;   -- things they're willing to give up

-- ────────────────────────────────────────────────────────────────────────────
-- 2. agent_profiles: account + licensing + onboarding-progress fields.
-- ────────────────────────────────────────────────────────────────────────────
alter table public.agent_profiles
  add column if not exists npn                  text,
  add column if not exists avatar_url           text,
  add column if not exists phone                text,
  add column if not exists signed_name          text,
  add column if not exists signed_at            timestamptz,
  add column if not exists licensed             boolean,
  add column if not exists onboarding_completed boolean not null default false,
  add column if not exists onboarding_step      int     not null default 0,
  add column if not exists onboarding_checks    jsonb   not null default '{}'::jsonb,  -- {eo, d1, d2, crm, cal}
  add column if not exists onboarding_videos    jsonb   not null default '{}'::jsonb,  -- {welcome, states, ...} watch %
  add column if not exists state_buys           jsonb   not null default '{}'::jsonb;  -- {Texas:true, ...}

-- Grandfather every CURRENT agent so nobody active is thrown into onboarding.
update public.agent_profiles set onboarding_completed = true where onboarding_completed is not true;

-- ────────────────────────────────────────────────────────────────────────────
-- 3. Auto-activate on completion.
--    The existing kf_guard_approved() trigger reverts any self-approval so a
--    pending user can't approve themselves. We extend it to allow ONE exception:
--    the same UPDATE that flips onboarding_completed from not-true → true may
--    also flip approved → true. That's the auto-activation at the end of the
--    flow. Every other self-approval attempt is still reverted.
-- ────────────────────────────────────────────────────────────────────────────
create or replace function public.kf_guard_approved()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if NEW.approved is distinct from OLD.approved then
    if not ( public.wt_is_admin()
             or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
             or public.kf_is_upline_of(NEW.user_id)
             or (NEW.onboarding_completed is true and OLD.onboarding_completed is distinct from true) ) then
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

-- ────────────────────────────────────────────────────────────────────────────
-- 4. Let the invited agent read + write THEIR OWN linked recruit row, so the
--    goals/profile they enter in onboarding land on the exact row Recruiter HQ
--    shows. A guard trigger locks the pipeline-control columns (stage, status,
--    recruiter, link, etc.) so a self-editing recruit can only touch their own
--    profile/goal fields — never move themselves through the pipeline.
-- ────────────────────────────────────────────────────────────────────────────
drop policy if exists "recruit reads own linked row" on public.recruits;
create policy "recruit reads own linked row" on public.recruits
  for select using (linked_user_id = auth.uid());

drop policy if exists "recruit updates own linked row" on public.recruits;
create policy "recruit updates own linked row" on public.recruits
  for update using (linked_user_id = auth.uid())
              with check (linked_user_id = auth.uid());

create or replace function public.kf_guard_recruit_self()
returns trigger
language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  -- Only clamp when the editor IS the linked recruit and NOT an admin. Admins
  -- and upline managers editing via Recruiter HQ keep full control.
  if auth.uid() = OLD.linked_user_id
     and not ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid ) then
    NEW.stage             := OLD.stage;
    NEW.status            := OLD.status;
    NEW.recruiter_user_id := OLD.recruiter_user_id;
    NEW.linked_user_id    := OLD.linked_user_id;
    NEW.link_status       := OLD.link_status;
    NEW.created_by        := OLD.created_by;
    NEW.abandoned_at      := OLD.abandoned_at;
    NEW.stage_entered_at  := OLD.stage_entered_at;
  end if;
  return NEW;
end;
$$;

drop trigger if exists kf_guard_recruit_self_trg on public.recruits;
create trigger kf_guard_recruit_self_trg
  before update on public.recruits
  for each row execute function public.kf_guard_recruit_self();

-- ────────────────────────────────────────────────────────────────────────────
-- 5. Avatar storage. A public `avatars` bucket; anyone can READ (so the photo
--    shows across the app), but a user can only write files under their own
--    uid folder (path = "<uid>/avatar.jpg").
-- ────────────────────────────────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "avatars public read" on storage.objects;
create policy "avatars public read" on storage.objects
  for select using (bucket_id = 'avatars');

drop policy if exists "avatars owner insert" on storage.objects;
create policy "avatars owner insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars owner update" on storage.objects;
create policy "avatars owner update" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "avatars owner delete" on storage.objects;
create policy "avatars owner delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
-- ============================================================================
