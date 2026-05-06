-- ============================================================================
-- Bulk import: 26 deals for Ebrahim (5 "6 Lost" rows skipped)
-- Run this in Supabase SQL Editor while logged in as admin.
-- ============================================================================

DO $$
DECLARE
  v_setter_id uuid;
BEGIN
  -- Fuzzy-match the rep name so it works whether you typed "Ebrahim" or "Ibrahim"
  SELECT id INTO v_setter_id
  FROM public.deal_tracker_setters
  WHERE name ILIKE '%brahim%'
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_setter_id IS NULL THEN
    RAISE EXCEPTION 'No sales rep matching "brahim" found. Add the rep in the admin panel first.';
  END IF;

  INSERT INTO public.deal_tracker_deals
    (setter_id, client, ap, commission, deal_date, status, paid, chargeback)
  VALUES
    (v_setter_id, 'John Barcelos',          0,     220, current_date, 'approved',     false, false),
    (v_setter_id, 'Annie Beatty',           10000, 220, '2026-05-01', 'approved',     false, false),
    (v_setter_id, 'Betty Smith',            0,     220, '2026-05-10', 'uw_submitted', false, false),
    (v_setter_id, 'Mary Katherine',         0,     220, current_date, 'uw_submitted', false, false),
    (v_setter_id, 'June Eastridge',         0,     220, '2026-05-05', 'uw_submitted', false, false),
    (v_setter_id, 'Joel Walkes',            20000, 220, '2026-05-03', 'approved',     false, false),
    (v_setter_id, 'Terrence D Sherrod',     0,     220, '2026-05-01', 'approved',     false, false),
    (v_setter_id, 'Donald F Bild',          0,     220, '2026-05-03', 'approved',     false, false),
    (v_setter_id, 'Alberto Sanchez',        12000, 220, '2026-05-18', 'approved',     false, false),
    (v_setter_id, 'Marion Sanchez',         15000, 220, '2026-06-18', 'approved',     false, false),
    (v_setter_id, 'Gloria M Fontenot',      0,     220, '2026-05-04', 'issued',       true,  false),
    (v_setter_id, 'Cassandra Robertson',    15000, 220, current_date, 'issued',       true,  false),
    (v_setter_id, 'Angie Crosby',           0,     220, current_date, 'issued',       true,  false),
    (v_setter_id, 'Joseph Albertine',       0,     220, current_date, 'issued',       true,  false),
    (v_setter_id, 'Theodore Bravely',       0,     220, current_date, 'issued',       true,  false),
    (v_setter_id, 'Jeffery Stone',          0,     220, current_date, 'issued',       true,  false),
    (v_setter_id, 'Phyllis Jones',          0,     220, '2026-05-04', 'issued',       true,  false),
    (v_setter_id, 'Vickey H Thomas',        8000,  220, '2026-05-03', 'approved',     false, false),
    (v_setter_id, 'Helen M Zachery',        5000,  220, current_date, 'approved',     false, false),
    (v_setter_id, 'Debbie S Anderson',      12000, 220, '2026-05-03', 'approved',     false, false),
    (v_setter_id, 'Annie D Spruill',        10000, 220, '2026-04-30', 'approved',     false, false),
    (v_setter_id, 'William W Cosnahan',     10000, 220, '2026-05-03', 'approved',     false, false),
    (v_setter_id, 'Louise D Smith',         0,     220, '2026-05-03', 'approved',     false, false),
    (v_setter_id, 'Marthenia D Dupree',     5000,  220, '2026-05-03', 'approved',     false, false),
    (v_setter_id, 'Ruth N Gingerich',       10000, 220, current_date, 'approved',     false, false),
    (v_setter_id, 'Johnny S Browning',      5000,  220, current_date, 'approved',     false, false);

  RAISE NOTICE 'Imported 26 deals for setter id %', v_setter_id;
END $$;
