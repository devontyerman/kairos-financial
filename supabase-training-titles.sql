-- =====================================================================
-- Training Videos — admin-editable video names (one-time setup)
-- Run in: Supabase Dashboard → SQL Editor → New query → paste → Run.
--
-- Creates a tiny table that stores custom video names keyed by each
-- video's slug. Everyone can READ it (so renames show for all reps);
-- only the admin account can WRITE it. The training page reads this on
-- load and overrides the default names from the code.
--
-- SAFE to re-run.
-- =====================================================================

create table if not exists public.training_titles (
  slug       text primary key,
  title      text not null,
  updated_at timestamptz not null default now()
);

alter table public.training_titles enable row level security;

-- Everyone with the publishable key can READ
drop policy if exists "training_titles read" on public.training_titles;
create policy "training_titles read"
  on public.training_titles for select
  to anon, authenticated
  using (true);

-- Only the admin user (Devon) can INSERT / UPDATE / DELETE.
-- Keyed by user ID so it survives an email change.
drop policy if exists "training_titles admin write" on public.training_titles;
create policy "training_titles admin write"
  on public.training_titles for all
  to authenticated
  using (auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid)
  with check (auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid);
