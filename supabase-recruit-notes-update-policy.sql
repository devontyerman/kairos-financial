-- ============================================================================
-- Recruit notes — UPDATE policy (enables editing notes in the Recruiting tab)
-- ============================================================================
-- Background:
--   public.recruit_notes already has RLS with SELECT / INSERT / DELETE policies
--   (see supabase-recruiter-hq-migration.sql). There was no UPDATE policy, so
--   with RLS enabled every PATCH is rejected — the new "edit note" button would
--   silently fail. This adds the missing UPDATE policy.
--
-- Security model (matches the existing select/insert policies):
--   • Admin (wt_is_admin() / owner user_id) can edit any note.
--   • The note's author can edit their own note.
--   • The recruit's recruiter, or an upline manager, can edit notes on that
--     recruit (kf_is_upline_of already requires the caller to be a manager).
--   Regular agents can neither read nor edit notes about themselves — the
--   existing SELECT policy blocks reads, and this USING clause blocks edits.
-- ============================================================================

drop policy if exists "recruit_notes_update" on public.recruit_notes;
create policy "recruit_notes_update" on public.recruit_notes
  for update to authenticated
  using ( public.wt_is_admin()
          or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
          or author_user_id = auth.uid()
          or exists (select 1 from public.recruits r
                     where r.id = recruit_id
                       and ( r.recruiter_user_id = auth.uid()
                             or public.kf_is_upline_of(r.recruiter_user_id) )) )
  with check ( public.wt_is_admin()
               or auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid
               or author_user_id = auth.uid()
               or exists (select 1 from public.recruits r
                          where r.id = recruit_id
                            and ( r.recruiter_user_id = auth.uid()
                                  or public.kf_is_upline_of(r.recruiter_user_id) )) );
