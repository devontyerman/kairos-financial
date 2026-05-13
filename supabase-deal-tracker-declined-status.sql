-- ============================================================================
-- Deal Tracker — add 'declined' to the allowed status values
-- Run this in Supabase SQL Editor.
-- ----------------------------------------------------------------------------
-- The status column has a CHECK constraint limiting it to four values.
-- This migration drops that constraint and recreates it with 'declined' added,
-- so reps can mark deals the carrier rejected.
-- ============================================================================

alter table public.deal_tracker_deals
  drop constraint if exists deal_tracker_deals_status_check;

alter table public.deal_tracker_deals
  add constraint deal_tracker_deals_status_check
  check (status in ('uw_submitted','approved','issued','pending_lapse','declined'));
