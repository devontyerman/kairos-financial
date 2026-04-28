-- Adds a book_visible flag so reps can "delete" a policy from their personal
-- book of business view without removing it from leaderboard / performance
-- aggregates. Existing rows default to TRUE.
--
-- Run this once in Supabase SQL editor.

ALTER TABLE policies
  ADD COLUMN IF NOT EXISTS book_visible BOOLEAN NOT NULL DEFAULT TRUE;

-- Optional: index for the rep's filtered listing queries
CREATE INDEX IF NOT EXISTS policies_user_book_visible_idx
  ON policies (user_id, book_visible);
