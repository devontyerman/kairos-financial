-- ============================================================================
-- "Kairos x Enzo" white-label for Frank Acierno's hierarchy
-- ----------------------------------------------------------------------------
-- Agents who ARE Frank Acierno, or are anywhere in his downline, should see the
-- Sales Hub branded "Kairos x Enzo" instead of "Kairos Financial".
--
-- This function returns whether the CURRENT signed-in user is in that group. It
-- walks up the org chart (agent_profiles.manager_user_id) from the caller and
-- checks whether Frank is the caller or any ancestor. security definer so it can
-- traverse the whole hierarchy regardless of the caller's RLS visibility.
--
-- ⚠️ If Frank's account name is stored differently, edit the name on the marked
--    line below. If there are multiple "Acierno" accounts, this uses the exact
--    "Frank Acierno" match only.
--
-- Safe to run more than once.
-- ============================================================================
create or replace function public.kf_in_enzo_hierarchy()
returns boolean
language sql
security definer
set search_path = public, pg_temp
stable
as $$
  with recursive top as (
    select user_id
      from public.agent_profiles
     where lower(btrim(agent_name)) = lower('Frank Acierno')   -- ← EDIT if his name differs
     limit 1
  ),
  chain as (
    select user_id, manager_user_id, 1 as depth
      from public.agent_profiles
     where user_id = auth.uid()
    union all
    select ap.user_id, ap.manager_user_id, c.depth + 1
      from public.agent_profiles ap
      join chain c on ap.user_id = c.manager_user_id
     where c.depth < 50 and c.manager_user_id is not null
  )
  select coalesce(
    (select exists (
       select 1 from chain c where c.user_id = (select user_id from top)
     )), false);
$$;

grant execute on function public.kf_in_enzo_hierarchy() to authenticated;
-- ============================================================================
