-- ============================================================================
-- DEAL TRACKER — schema + RLS + RPC functions
-- ----------------------------------------------------------------------------
-- Powers /deal-tracker. Fully isolated from the rest of the site:
--   - Tables are prefixed `deal_tracker_*`
--   - RLS denies anon SELECT on the tables themselves
--   - Reps read their own data through SECURITY DEFINER RPC functions that
--     validate by access code, so access codes are never exposed via REST
--   - Only admin email (dev@kairos-financial.com) can INSERT/UPDATE/DELETE
-- ============================================================================

-- 1. SETTERS ------------------------------------------------------------------
create table if not exists public.deal_tracker_setters (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  access_code  text not null unique,
  created_at   timestamptz not null default now()
);

create index if not exists deal_tracker_setters_access_code_idx
  on public.deal_tracker_setters (access_code);

-- 2. DEALS --------------------------------------------------------------------
create table if not exists public.deal_tracker_deals (
  id          uuid primary key default gen_random_uuid(),
  setter_id   uuid not null references public.deal_tracker_setters(id) on delete cascade,
  client      text not null,
  ap          numeric(12,2) not null default 0,
  commission  numeric(12,2) not null default 0,
  deal_date   date not null default current_date,
  status      text not null default 'uw_submitted'
              check (status in ('uw_submitted','approved','issued','pending_lapse')),
  paid        boolean not null default false,
  chargeback  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists deal_tracker_deals_setter_idx
  on public.deal_tracker_deals (setter_id);

-- Auto-update updated_at on every UPDATE
create or replace function public.deal_tracker_touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists deal_tracker_deals_touch on public.deal_tracker_deals;
create trigger deal_tracker_deals_touch
before update on public.deal_tracker_deals
for each row execute function public.deal_tracker_touch_updated_at();

-- 3. ROW-LEVEL SECURITY -------------------------------------------------------
alter table public.deal_tracker_setters enable row level security;
alter table public.deal_tracker_deals   enable row level security;

-- Setters: admin-only access via REST. Reps must use the RPC functions below.
drop policy if exists "deal_tracker_setters_admin_all" on public.deal_tracker_setters;
create policy "deal_tracker_setters_admin_all"
on public.deal_tracker_setters
for all
using  (auth.jwt() ->> 'email' = 'dev@kairos-financial.com')
with check (auth.jwt() ->> 'email' = 'dev@kairos-financial.com');

-- Deals: same — admin-only via REST.
drop policy if exists "deal_tracker_deals_admin_all" on public.deal_tracker_deals;
create policy "deal_tracker_deals_admin_all"
on public.deal_tracker_deals
for all
using  (auth.jwt() ->> 'email' = 'dev@kairos-financial.com')
with check (auth.jwt() ->> 'email' = 'dev@kairos-financial.com');

-- 4. RPC FUNCTIONS FOR REPS (access-code-gated, view-only) --------------------

-- Validate an access code. Returns the setter id + name if valid, else empty.
-- Access codes are NEVER returned by this function.
create or replace function public.verify_setter_code(p_code text)
returns table (id uuid, name text)
language sql
security definer
set search_path = public
as $$
  select s.id, s.name
  from public.deal_tracker_setters s
  where s.access_code = p_code
  limit 1;
$$;

-- Fetch all deals for a setter, gated by their access code.
create or replace function public.get_setter_deals(p_code text)
returns table (
  id uuid,
  setter_id uuid,
  client text,
  ap numeric,
  commission numeric,
  deal_date date,
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
  select d.id, d.setter_id, d.client, d.ap, d.commission, d.deal_date,
         d.status, d.paid, d.chargeback, d.created_at, d.updated_at
  from public.deal_tracker_deals d
  join public.deal_tracker_setters s on s.id = d.setter_id
  where s.access_code = p_code
  order by d.deal_date desc, d.created_at desc;
$$;

-- Allow anon + authenticated to call the RPCs.
grant execute on function public.verify_setter_code(text) to anon, authenticated;
grant execute on function public.get_setter_deals(text)   to anon, authenticated;

-- ============================================================================
-- DONE. After running this in Supabase SQL editor:
--   1. Open /deal-tracker on the site
--   2. Click "Admin login" (top-right), sign in as dev@kairos-financial.com
--   3. Add a sales rep + custom access code from the admin panel
--   4. Share the URL + access code with the rep
-- ============================================================================
