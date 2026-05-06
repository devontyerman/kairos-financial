-- ============================================================================
-- Deal Tracker — add effective_date, rename existing date semantics
-- Run this in Supabase SQL Editor.
-- ----------------------------------------------------------------------------
-- 1. deal_date stays (now means "date sold"); make it nullable so reps can
--    import deals where the sold date is unknown.
-- 2. Add effective_date (when the policy becomes effective; nullable).
-- 3. Backfill: deals previously imported from the CSV used `deal_date` to hold
--    what was really the *effective* date. Move those values into the new
--    column for any deal whose setter name fuzzy-matches "brahim".
-- ============================================================================

alter table public.deal_tracker_deals
  alter column deal_date drop not null;

alter table public.deal_tracker_deals
  add column if not exists effective_date date;

-- One-time backfill for Ebrahim's imported deals.
-- Safe to run multiple times: only touches rows where effective_date is still null.
update public.deal_tracker_deals d
set effective_date = d.deal_date,
    deal_date = null
from public.deal_tracker_setters s
where d.setter_id = s.id
  and s.name ilike '%brahim%'
  and d.effective_date is null;

-- Update the RPC so reps see the new column too.
-- Postgres can't change a function's return shape via CREATE OR REPLACE,
-- so drop it first. Dropping wipes its grants, so re-grant after.
drop function if exists public.get_setter_deals(text);

create function public.get_setter_deals(p_code text)
returns table (
  id uuid,
  setter_id uuid,
  client text,
  ap numeric,
  commission numeric,
  deal_date date,
  effective_date date,
  status text,
  paid boolean,
  chargeback boolean,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select d.id, d.setter_id, d.client, d.ap, d.commission,
         d.deal_date, d.effective_date,
         d.status, d.paid, d.chargeback, d.created_at, d.updated_at
  from public.deal_tracker_deals d
  join public.deal_tracker_setters s on s.id = d.setter_id
  where s.access_code = p_code
  order by d.deal_date desc nulls last, d.created_at desc;
$$;

grant execute on function public.get_setter_deals(text) to anon, authenticated;
