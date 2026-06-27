-- ============================================================================
-- Policies — add approved_on_submit (same-day approval flag)
-- Run this in Supabase SQL Editor.
-- ----------------------------------------------------------------------------
-- Powers the tracker's Approval Rate KPI: the % of submitted deals that were
-- approved THE SAME DAY they were submitted (vs sent to underwriting).
--
-- This must be an immutable point-of-sale signal — a deal sent to underwriting
-- should NEVER count toward approval rate, even if it gets approved later. The
-- submit form stamps it true only when the rep picks "Approved" at submission.
--
-- Safe to run multiple times.
-- ============================================================================

-- 1. Add the column. Default false so any future insert that forgets to set it
--    is treated as "not approved at submission" rather than null/unknown.
alter table public.policies
  add column if not exists approved_on_submit boolean not null default false;

-- 2. One-time historical backfill. Old rows don't carry the submission-time
--    status, so this is a best-effort estimate from current status: anything
--    currently Approved or Issue Paid is assumed to have been approved at
--    submission. This is imperfect for legacy deals that went to underwriting
--    first and were approved later — that history simply wasn't recorded.
--    Everything submitted from go-live forward is exact.
update public.policies
set approved_on_submit = (status in ('Approved', 'Issue Paid'))
where approved_on_submit is distinct from (status in ('Approved', 'Issue Paid'));
