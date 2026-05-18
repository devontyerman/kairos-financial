-- =====================================================================
-- Training Videos — migration #3
-- Reorder sections so "CRM Guide" is the LAST step, with
-- "Products & Underwriting" immediately before it.
--
-- Why this is safe for progress tracking:
--   The saleshub Training panel renders sections/videos purely by
--   `sort_order`, and per-user completion in `video_progress` is keyed
--   by each video's text `slug` (NOT by section or sort_order). This
--   migration only touches `training_sections.sort_order`, so no slugs
--   change and every agent keeps their completed-video state. The only
--   effect is that the sequential unlock now ends on the CRM Guide.
--
-- SAFE to re-run (idempotent — matches sections by title).
-- Run in: Supabase Dashboard → SQL Editor → New query → paste → Run.
-- =====================================================================

-- Target order:
--   New Agent Steps          → 10
--   Licensing                → 20
--   Products & Underwriting  → 30
--   CRM Guide                → 40   (last)
update public.training_sections set sort_order = 10 where title = 'New Agent Steps';
update public.training_sections set sort_order = 20 where title = 'Licensing';
update public.training_sections set sort_order = 30 where title = 'Products & Underwriting';
update public.training_sections set sort_order = 40 where title = 'CRM Guide';

-- Verify the new order after running:
select title, sort_order
from public.training_sections
order by sort_order asc;
