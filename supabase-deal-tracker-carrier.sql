-- ============================================================================
-- Deal Tracker — add carrier column, blank existing AP, backfill carriers
-- Run this in Supabase SQL Editor.
-- ============================================================================

-- 1. Add carrier column (nullable text).
alter table public.deal_tracker_deals
  add column if not exists carrier text;

-- 2. Make AP nullable so deals can record no premium amount.
alter table public.deal_tracker_deals
  alter column ap drop not null;

-- 3. Blank the AP on every deal Ebrahim has (existing values were wrong).
update public.deal_tracker_deals d
set ap = null
from public.deal_tracker_setters s
where d.setter_id = s.id
  and s.name ilike '%brahim%';

-- 4. Backfill carrier per CSV.
update public.deal_tracker_deals d
set carrier = case d.client
  when 'Annie Beatty'         then 'CICA'
  when 'Betty Smith'          then 'American Amicable'
  when 'Mary Katherine'       then 'American Amicable'
  when 'June Eastridge'       then 'American Amicable'
  when 'Joel Walkes'          then 'TransAmerica'
  when 'Terrence D Sherrod'   then 'Ethos'
  when 'Donald F Bild'        then 'Aetna'
  when 'Alberto Sanchez'      then 'Ethos'
  when 'Marion Sanchez'       then 'TransAmerica'
  when 'Gloria M Fontenot'    then 'Ethos'
  when 'Cassandra Robertson'  then 'TransAmerica'
  when 'Angie Crosby'         then 'TransAmerica'
  when 'Joseph Albertine'     then 'American Amicable'
  when 'Theodore Bravely'     then 'Mutual of Omaha'
  when 'Jeffery Stone'        then 'Mutual of Omaha'
  when 'Phyllis Jones'        then 'Ethos'
  when 'Vickey H Thomas'      then 'TransAmerica'
  when 'Helen M Zachery'      then 'CICA'
  when 'Debbie S Anderson'    then 'CICA'
  when 'Annie D Spruill'      then 'Liberty Bankers'
  when 'William W Cosnahan'   then 'CICA'
  when 'Louise D Smith'       then 'CICA'
  when 'Marthenia D Dupree'   then 'AIG'
  when 'Ruth N Gingerich'     then 'CICA'
  when 'Johnny S Browning'    then 'Liberty Bankers'
  else d.carrier
end
from public.deal_tracker_setters s
where d.setter_id = s.id
  and s.name ilike '%brahim%';

-- 5. Recreate the rep-facing RPC to expose the new column.
drop function if exists public.get_setter_deals(text);

create function public.get_setter_deals(p_code text)
returns table (
  id uuid,
  setter_id uuid,
  client text,
  ap numeric,
  commission numeric,
  carrier text,
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
  select d.id, d.setter_id, d.client, d.ap, d.commission, d.carrier,
         d.deal_date, d.effective_date,
         d.status, d.paid, d.chargeback, d.created_at, d.updated_at
  from public.deal_tracker_deals d
  join public.deal_tracker_setters s on s.id = d.setter_id
  where s.access_code = p_code
  order by d.deal_date desc nulls last, d.created_at desc;
$$;

grant execute on function public.get_setter_deals(text) to anon, authenticated;
