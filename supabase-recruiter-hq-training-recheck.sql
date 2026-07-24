-- ============================================================================
-- RECRUITER HQ: re-check training → move not-yet-trained agents to "Training"
-- ----------------------------------------------------------------------------
-- The original backfill placed every agent at "Fully licensed" (stage 4). This
-- corrects that: any active, account-linked recruit currently at Fully licensed
-- who has NOT completed training is moved to the Training stage (5).
--
-- "Training complete" mirrors the app's own gate (saleshub.html computeGate):
--   • admin granted full access (agent_profiles.training_complete = true), OR
--   • grandfathered — account created before the training go-live cutoff
--     (2026-06-04T05:00:00Z); these are established reps who predate the video
--     gate, so they stay Fully licensed, OR
--   • they have completed ALL 14 required (non-optional) training videos.
--
-- Anyone who is NONE of the above is still working through the videos → Training.
-- Agents who later finish all required videos are auto-promoted back to Fully
-- licensed by the training page (kf_promote_trainee_to_licensed), so this only
-- ever needs to move people INTO Training; re-running it is safe.
--
-- Run in the Supabase SQL Editor (after the Training-stage migration).
-- ============================================================================

update public.recruits r
set stage = 5                              -- Training
from public.agent_profiles ap
join auth.users au on au.id = ap.user_id
where r.linked_user_id = ap.user_id
  and r.status = 'active'
  and r.stage = 4                          -- only the "Fully licensed" backfill rows
  and coalesce(ap.training_complete, false) = false            -- not admin-granted
  and au.created_at >= '2026-06-04T05:00:00Z'::timestamptz     -- not grandfathered by date
  and (
        select count(distinct vp.video_id)
        from public.video_progress vp
        where vp.user_id = ap.user_id
          and vp.video_id in (
            'first-90-days','navigating-discord','submit-a-sale',
            'carrier-contracting','purchase-licenses','after-state-license',
            'call-intro-script','insurance-presentation','overcome-objections',
            'ca-studios','sales-recordings','product-selection',
            'underwriting-guide','carrier-applications-portal')
      ) < 14                               -- hasn't finished all 14 current videos
  and (
        -- ...and didn't complete the OLD pre-revamp training either (legacy slugs).
        select count(distinct vp.video_id)
        from public.video_progress vp
        where vp.user_id = ap.user_id
          and vp.video_id in (
            'watch-first-new-agents','discord-walkthrough','submit-new-sale',
            'script-sales-presentation','buy-state-licenses','next-steps-licenses')
      ) < 4;

-- ── Verify: stage distribution after the move ───────────────────────────────
-- select stage, count(*) from public.recruits where status='active' group by 1 order by 1;
--
-- ── Preview who WOULD move (run the SELECT before the UPDATE if you want) ────
-- select ap.agent_name, au.created_at,
--        (select count(distinct vp.video_id) from public.video_progress vp
--         where vp.user_id=ap.user_id and vp.video_id in (
--           'first-90-days','navigating-discord','submit-a-sale','carrier-contracting',
--           'purchase-licenses','after-state-license','call-intro-script','insurance-presentation',
--           'overcome-objections','ca-studios','sales-recordings','product-selection',
--           'underwriting-guide','carrier-applications-portal')) as required_done
--   from public.recruits r
--   join public.agent_profiles ap on ap.user_id=r.linked_user_id
--   join auth.users au on au.id=ap.user_id
--   where r.status='active' and r.stage=4
--     and coalesce(ap.training_complete,false)=false
--     and au.created_at >= '2026-06-04T05:00:00Z'::timestamptz
--   order by required_done desc;
-- ============================================================================
