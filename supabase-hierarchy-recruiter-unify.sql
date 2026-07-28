-- ============================================================================
-- Unify the Sales Hub org hierarchy with the recruiting pipeline upline.
--
-- "Reports to" lives in  agent_profiles.manager_user_id
-- "Recruiter / upline"    lives in  recruits.recruiter_user_id
--
-- Going forward the app keeps these two in sync automatically (a reparent in
-- the hierarchy, or an edit to the single "Upline · reports-to" control on a
-- recruit, writes both). This one-time backfill aligns EXISTING rows that have
-- already drifted apart.
--
-- Direction: the actively-managed org chart (manager_user_id) is treated as the
-- source of truth, so we copy it onto the matching recruit's recruiter_user_id.
-- Run once in the Supabase SQL editor. Safe to re-run (idempotent).
-- ============================================================================

-- 1) For every recruit linked to a Sales Hub account whose org-chart manager is
--    set, make the pipeline recruiter match that manager.
update public.recruits r
set    recruiter_user_id = ap.manager_user_id
from   public.agent_profiles ap
where  r.linked_user_id = ap.user_id
  and  ap.manager_user_id is not null
  and  r.recruiter_user_id is distinct from ap.manager_user_id;

-- 2) Sanity check — rows that still differ after the backfill (expected: only
--    linked agents who sit at the top of the org with no manager set). Review
--    these manually if the count is non-zero and unexpected.
select r.id,
       r.full_name,
       r.recruiter_user_id      as pipeline_recruiter,
       ap.manager_user_id       as hierarchy_manager
from   public.recruits r
join   public.agent_profiles ap on ap.user_id = r.linked_user_id
where  r.recruiter_user_id is distinct from ap.manager_user_id;
