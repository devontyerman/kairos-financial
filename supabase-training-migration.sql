-- =====================================================================
-- Training Videos — one-time Supabase migration
-- Run this in: Supabase Dashboard → SQL Editor → New query → paste → Run
-- =====================================================================

-- 1) Tables -----------------------------------------------------------
create table if not exists public.training_sections (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.training_videos (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references public.training_sections(id) on delete cascade,
  title text not null,
  loom_url text not null,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists training_videos_section_idx
  on public.training_videos (section_id);

-- 2) Row-Level Security ----------------------------------------------
alter table public.training_sections enable row level security;
alter table public.training_videos   enable row level security;

-- Everyone with the publishable key can READ
drop policy if exists "training_sections read public" on public.training_sections;
create policy "training_sections read public"
  on public.training_sections for select
  to anon, authenticated
  using (true);

drop policy if exists "training_videos read public" on public.training_videos;
create policy "training_videos read public"
  on public.training_videos for select
  to anon, authenticated
  using (true);

-- Only the admin user can WRITE (insert / update / delete)
-- Keyed by user ID so it survives an email change
drop policy if exists "training_sections admin write" on public.training_sections;
create policy "training_sections admin write"
  on public.training_sections for all
  to authenticated
  using (auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid)
  with check (auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid);

drop policy if exists "training_videos admin write" on public.training_videos;
create policy "training_videos admin write"
  on public.training_videos for all
  to authenticated
  using (auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid)
  with check (auth.uid() = 'be364ef5-8426-4587-b8b8-9328b02055a7'::uuid);

-- 3) Seed existing videos (only if table is empty) -------------------
do $$
begin
  if not exists (select 1 from public.training_sections limit 1) then

    insert into public.training_sections (title, sort_order) values
      ('New Agent Steps',         10),
      ('Licensing',               20),
      ('CRM Guide',               30),
      ('Products & Underwriting', 40),
      ('Leads',                   50);

    insert into public.training_videos (section_id, title, loom_url, sort_order)
    select s.id, v.title, v.loom_url, v.sort_order
    from public.training_sections s
    join (values
      ('New Agent Steps',         'Watch First New Agents',                  'https://www.loom.com/embed/a30581bfa9ce43239b8292d32cb8e802', 10),
      ('New Agent Steps',         'Discord Walk Through',                    'https://www.loom.com/embed/2655d8ef38ea49338d1f37c8231faf90', 20),
      ('New Agent Steps',         'How to Update Discord Leaderboard',       'https://www.loom.com/embed/1dce58e1623847dabcad03668ac14854', 30),
      ('New Agent Steps',         'How to Submit a New Sale',                'https://www.loom.com/embed/bb4bec1445d94890a3a56a81152cfdc4', 40),
      ('New Agent Steps',         'AI Training Bot',                         'https://www.loom.com/embed/5504b88cb4474dbc9b0d3f1d0fa5e914', 50),
      ('New Agent Steps',         'Script and Sales Presentation',           'https://www.loom.com/embed/f693b1b3369c4655963fce11856f8a56', 60),

      ('Licensing',               'How To Buy Additional State Licenses',    'https://www.loom.com/embed/badf77aa57d0430e817936e469eb6b56', 10),
      ('Licensing',               'Next Steps After Buying Licenses',        'https://www.loom.com/embed/96cc1263b9a446e583b9f8d356a2c90a', 20),

      ('CRM Guide',               'How to Access CRM',                       'https://www.loom.com/embed/9ab847bb22af4c8ab2f5063d5b0981fe', 10),
      ('CRM Guide',               'Setting Up Your Phone Numbers',           'https://www.loom.com/embed/a2008c417a7e488ba749428d1d72191c', 20),
      ('CRM Guide',               'A2P Texting Verification',                'https://www.loom.com/embed/0a94c4d2e15e40dcaaa0817631b51dfe', 30),
      ('CRM Guide',               'Setting Up Wavv',                         'https://www.loom.com/embed/e04fb59f584c467c8231fd614123f244', 40),
      ('CRM Guide',               'Uploading Leads',                         'https://www.loom.com/embed/f6ebb4995f2a4d2a921658e022aa4067', 50),
      ('CRM Guide',               'Calendar and Booking Appointments',       'https://www.loom.com/embed/ce38f87fb64046e3b669e1d4da4c616a', 60),
      ('CRM Guide',               'Using & Building Automations',            'https://www.loom.com/embed/10dfa99d2d48470681b52f5ac7c16b4e', 70),

      ('Products & Underwriting', 'Product Selection',                       'https://www.loom.com/embed/2c156fff8cc8472e8281f6faef0e2dcb', 10),
      ('Products & Underwriting', 'Insurance Toolkits and Underwriting',     'https://www.loom.com/embed/d7c56c9e50574348a2dec7292274d5a4', 20),
      ('Products & Underwriting', 'Americo Application Walkthrough',         'https://www.loom.com/embed/bcd4adb557dc4446958b4999226c9abe', 30),
      ('Products & Underwriting', 'Transamerica Application Walkthrough',    'https://www.loom.com/embed/e91098314c6b4641a049921959902aff', 40),
      ('Products & Underwriting', 'Mutual Of Omaha Application Walkthrough', 'https://www.loom.com/embed/dd390290b98542218101fbbcacaf9fed', 50),

      ('Leads',                   'Watch Before Buying Leads',               'https://www.loom.com/embed/8a10f1b0e3e5492aa6fd5a09474d5962', 10),
      ('Leads',                   'Ethos Leads',                             'https://www.loom.com/embed/83d778600ded478282e1dd8ae4c2cf43', 20),
      ('Leads',                   'Goat Leads',                              'https://www.loom.com/embed/66189350089e4517826b1d2d975f894a', 30),
      ('Leads',                   'Freedom Life Leads',                      'https://www.loom.com/embed/84e1a440093b4799a5c70af16ee92130', 40)
    ) as v(section_title, title, loom_url, sort_order)
      on s.title = v.section_title;

  end if;
end $$;
