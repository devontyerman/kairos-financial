-- =====================================================================
-- Training Videos — cleanup after the R2 revamp (OPTIONAL housekeeping)
-- Run in: Supabase Dashboard → SQL Editor → New query → paste → Run.
--
-- Context: the new training video list now lives in the saleshub.html
-- code (custom R2 player). Supabase is used only to TRACK per-rep
-- completion in `video_progress` (keyed by each video's text slug).
--
-- This script removes the old Loom-era rows. It is SAFE: the live site
-- no longer reads training_sections / training_videos at all, and access
-- for existing reps does not depend on video_progress (they're granted
-- full access by account age). Brand-new reps start with no rows.
--
-- SAFE to re-run.
-- =====================================================================

-- 1) Drop the old Loom-based catalog (no longer read by the app).
delete from public.training_videos;
delete from public.training_sections;

-- 2) Clear stale per-user completion that was keyed by the OLD video
--    slugs (those videos no longer exist). Rows matching the NEW slugs
--    are kept so any progress already recorded under the new system
--    survives.
delete from public.video_progress
 where video_id not in (
   'first-90-days','navigating-discord','submit-a-sale',
   'carrier-contracting','purchase-licenses','after-state-license',
   'call-intro-script','insurance-presentation','overcome-objections',
   'ca-studios','product-selection','underwriting-guide','carrier-applications-portal',
   'how-to-buy-crm','phone-numbers-texting','atp-registration','a2p-wave',
   'lead-management-pipeline','appointment-calendar','lead-management-automation'
 );

-- Verify:
-- select count(*) as old_sections from public.training_sections;   -- expect 0
-- select count(*) as old_videos   from public.training_videos;     -- expect 0
