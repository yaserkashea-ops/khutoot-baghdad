-- Schema for Baghdad shared transit listings (Supabase)
create table if not exists listings (
  id uuid primary key default gen_random_uuid(),
  listing_type text check (listing_type in ('driver','rider')) not null,
  area text not null,
  destination text not null,
  origin_subs text,
  destination_subs text,
  time_period text check (time_period in ('morning','evening')) not null,
  departure_time text,
  return_time text,
  vehicle_type text,
  seats_count int,
  gender_requirement text check (gender_requirement in ('male_only','female_only','mixed')) not null,
  contact_phone text,
  contact_telegram text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists admin_reports (
  id uuid primary key default gen_random_uuid(),
  kind text check (kind in ('report','complaint','problem')) not null,
  message text not null,
  status text check (status in ('open','in_progress','resolved','dismissed')) not null default 'open',
  listing_id uuid references listings(id) on delete set null,
  contact_hint text,
  admin_note text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_listings_area on listings(area);
create index if not exists idx_listings_destination on listings(destination);
create index if not exists idx_listings_time_period on listings(time_period);
create index if not exists idx_admin_reports_status on admin_reports(status);
