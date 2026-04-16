-- =====================================================================
-- Training Videos — migration #2
-- Adds slug + duration_seconds columns so progress tracking keeps working
-- after we move the saleshub Training panel to load from the DB.
--
-- SAFE to re-run. Run in: Supabase Dashboard → SQL Editor → Run.
-- =====================================================================

-- 1) Add columns -------------------------------------------------------
alter table public.training_videos
  add column if not exists slug text,
  add column if not exists duration_seconds int;

-- 2) Backfill slug + duration onto existing seeded rows ---------------
-- These slugs MUST match the string IDs already stored in `video_progress`
-- so agents don't lose their completion progress.
update public.training_videos set slug = 'watch-first-new-agents',         duration_seconds = 711  where loom_url = 'https://www.loom.com/embed/a30581bfa9ce43239b8292d32cb8e802' and slug is null;
update public.training_videos set slug = 'discord-walkthrough',            duration_seconds = 280  where loom_url = 'https://www.loom.com/embed/2655d8ef38ea49338d1f37c8231faf90' and slug is null;
update public.training_videos set slug = 'update-discord-leaderboard',     duration_seconds = 40   where loom_url = 'https://www.loom.com/embed/1dce58e1623847dabcad03668ac14854' and slug is null;
update public.training_videos set slug = 'submit-new-sale',                duration_seconds = 69   where loom_url = 'https://www.loom.com/embed/bb4bec1445d94890a3a56a81152cfdc4' and slug is null;
update public.training_videos set slug = 'ai-training-bot',                duration_seconds = 198  where loom_url = 'https://www.loom.com/embed/5504b88cb4474dbc9b0d3f1d0fa5e914' and slug is null;
update public.training_videos set slug = 'script-sales-presentation',      duration_seconds = 1202 where loom_url = 'https://www.loom.com/embed/f693b1b3369c4655963fce11856f8a56' and slug is null;

update public.training_videos set slug = 'buy-state-licenses',             duration_seconds = 260  where loom_url = 'https://www.loom.com/embed/badf77aa57d0430e817936e469eb6b56' and slug is null;
update public.training_videos set slug = 'next-steps-licenses',            duration_seconds = 292  where loom_url = 'https://www.loom.com/embed/96cc1263b9a446e583b9f8d356a2c90a' and slug is null;

update public.training_videos set slug = 'access-crm',                     duration_seconds = 45   where loom_url = 'https://www.loom.com/embed/9ab847bb22af4c8ab2f5063d5b0981fe' and slug is null;
update public.training_videos set slug = 'setup-phone-numbers',            duration_seconds = 108  where loom_url = 'https://www.loom.com/embed/a2008c417a7e488ba749428d1d72191c' and slug is null;
update public.training_videos set slug = 'a2p-texting',                    duration_seconds = 153  where loom_url = 'https://www.loom.com/embed/0a94c4d2e15e40dcaaa0817631b51dfe' and slug is null;
update public.training_videos set slug = 'setting-up-wavv',                duration_seconds = 366  where loom_url = 'https://www.loom.com/embed/e04fb59f584c467c8231fd614123f244' and slug is null;
update public.training_videos set slug = 'uploading-leads',                duration_seconds = 2038 where loom_url = 'https://www.loom.com/embed/f6ebb4995f2a4d2a921658e022aa4067' and slug is null;
update public.training_videos set slug = 'calendar-booking',               duration_seconds = 314  where loom_url = 'https://www.loom.com/embed/ce38f87fb64046e3b669e1d4da4c616a' and slug is null;
update public.training_videos set slug = 'building-automations',           duration_seconds = 1435 where loom_url = 'https://www.loom.com/embed/10dfa99d2d48470681b52f5ac7c16b4e' and slug is null;

update public.training_videos set slug = 'product-selection',              duration_seconds = 812  where loom_url = 'https://www.loom.com/embed/2c156fff8cc8472e8281f6faef0e2dcb' and slug is null;
update public.training_videos set slug = 'insurance-toolkits-underwriting',duration_seconds = 215  where loom_url = 'https://www.loom.com/embed/d7c56c9e50574348a2dec7292274d5a4' and slug is null;
update public.training_videos set slug = 'americo-walkthrough',            duration_seconds = 812  where loom_url = 'https://www.loom.com/embed/bcd4adb557dc4446958b4999226c9abe' and slug is null;
update public.training_videos set slug = 'transamerica-walkthrough',       duration_seconds = 671  where loom_url = 'https://www.loom.com/embed/e91098314c6b4641a049921959902aff' and slug is null;
update public.training_videos set slug = 'mutual-omaha-walkthrough',       duration_seconds = 1182 where loom_url = 'https://www.loom.com/embed/dd390290b98542218101fbbcacaf9fed' and slug is null;

update public.training_videos set slug = 'watch-before-buying-leads',      duration_seconds = 54   where loom_url = 'https://www.loom.com/embed/8a10f1b0e3e5492aa6fd5a09474d5962' and slug is null;
update public.training_videos set slug = 'ethos-leads',                    duration_seconds = 375  where loom_url = 'https://www.loom.com/embed/83d778600ded478282e1dd8ae4c2cf43' and slug is null;
update public.training_videos set slug = 'goat-leads',                     duration_seconds = 83   where loom_url = 'https://www.loom.com/embed/66189350089e4517826b1d2d975f894a' and slug is null;
update public.training_videos set slug = 'freedom-life-leads',             duration_seconds = 149  where loom_url = 'https://www.loom.com/embed/84e1a440093b4799a5c70af16ee92130' and slug is null;

-- 3) For any row that still has no slug (e.g. videos the admin added
--    between running the first migration and this one), generate a slug
--    from its id so it's never null going forward.
update public.training_videos
  set slug = 'v-' || substr(id::text, 1, 8)
  where slug is null;

-- 4) Default duration for anything missing (2 min is a safe default) --
update public.training_videos set duration_seconds = 120 where duration_seconds is null;

-- 5) Enforce constraints going forward --------------------------------
alter table public.training_videos alter column slug set not null;
alter table public.training_videos alter column duration_seconds set not null;

create unique index if not exists training_videos_slug_unique_idx
  on public.training_videos (slug);
