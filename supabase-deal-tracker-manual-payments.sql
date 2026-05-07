-- ============================================================================
-- DEAL TRACKER — manual payments (advances, bonuses not tied to a deal)
-- ----------------------------------------------------------------------------
-- Adds a per-setter ledger for ad-hoc payouts that should fold into the
-- "Paid out" KPI but aren't tied to a specific account/deal. Same RLS
-- pattern as the rest of /deal-tracker:
--   - Admin-only via REST
--   - Reps read their own via SECURITY DEFINER RPC, gated by access code
-- ============================================================================

create table if not exists public.deal_tracker_manual_payments (
  id            uuid primary key default gen_random_uuid(),
  setter_id     uuid not null references public.deal_tracker_setters(id) on delete cascade,
  payment_date  date not null default current_date,
  amount        numeric(12,2) not null default 0,
  note          text,
  created_at    timestamptz not null default now()
);

create index if not exists deal_tracker_manual_payments_setter_idx
  on public.deal_tracker_manual_payments (setter_id);

-- RLS — admin-only via REST (reps must use the RPC below)
alter table public.deal_tracker_manual_payments enable row level security;

drop policy if exists "deal_tracker_manual_payments_admin_all"
  on public.deal_tracker_manual_payments;
create policy "deal_tracker_manual_payments_admin_all"
on public.deal_tracker_manual_payments
for all
using  (auth.jwt() ->> 'email' = 'dev@kairos-financial.com')
with check (auth.jwt() ->> 'email' = 'dev@kairos-financial.com');

-- RPC — fetch a setter's manual payments by access code
create or replace function public.get_setter_manual_payments(p_code text)
returns table (
  id uuid,
  setter_id uuid,
  payment_date date,
  amount numeric,
  note text,
  created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select m.id, m.setter_id, m.payment_date, m.amount, m.note, m.created_at
  from public.deal_tracker_manual_payments m
  join public.deal_tracker_setters s on s.id = m.setter_id
  where s.access_code = p_code
  order by m.payment_date desc, m.created_at desc;
$$;

grant execute on function public.get_setter_manual_payments(text) to anon, authenticated;
