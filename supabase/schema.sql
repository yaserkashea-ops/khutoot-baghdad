-- خطوط بغداد — schema + open policies for current launch model
-- (public users have no auth; admin gate is app-local). Tighten later if needed.

create extension if not exists pgcrypto;

create table if not exists listings (
  id uuid primary key default gen_random_uuid(),
  listing_type text check (listing_type in ('driver','rider')) not null,
  area text not null,
  destination text not null,
  origin_subs text[] not null default '{}',
  destination_subs text[] not null default '{}',
  time_period text check (time_period in ('morning','evening')) not null,
  departure_time text,
  return_time text,
  vehicle_type text,
  seats_count int,
  gender_requirement text check (gender_requirement in ('male_only','female_only','mixed')) not null,
  contact_phone text,
  contact_telegram text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists admin_reports (
  id uuid primary key default gen_random_uuid(),
  kind text check (kind in ('report','complaint','problem')) not null,
  message text not null,
  status text check (status in ('open','in_progress','resolved','dismissed')) not null default 'open',
  listing_id uuid references listings(id) on delete set null,
  contact_hint text,
  admin_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_listings_area on listings(area);
create index if not exists idx_listings_destination on listings(destination);
create index if not exists idx_listings_time_period on listings(time_period);
create index if not exists idx_listings_created_at on listings(created_at desc);
create index if not exists idx_admin_reports_status on admin_reports(status);
create index if not exists idx_admin_reports_created_at on admin_reports(created_at desc);

create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists listings_set_updated_at on listings;
create trigger listings_set_updated_at
before update on listings
for each row execute function set_updated_at();

drop trigger if exists admin_reports_set_updated_at on admin_reports;
create trigger admin_reports_set_updated_at
before update on admin_reports
for each row execute function set_updated_at();

alter table listings enable row level security;
alter table admin_reports enable row level security;

-- Launch policies: anon client can do what the app already allows locally.
drop policy if exists listings_select_all on listings;
create policy listings_select_all on listings for select using (true);

drop policy if exists listings_insert_all on listings;
create policy listings_insert_all on listings for insert with check (true);

drop policy if exists listings_update_all on listings;
create policy listings_update_all on listings for update using (true) with check (true);

drop policy if exists listings_delete_all on listings;
create policy listings_delete_all on listings for delete using (true);

drop policy if exists reports_select_all on admin_reports;
create policy reports_select_all on admin_reports for select using (true);

drop policy if exists reports_insert_all on admin_reports;
create policy reports_insert_all on admin_reports for insert with check (true);

drop policy if exists reports_update_all on admin_reports;
create policy reports_update_all on admin_reports for update using (true) with check (true);

drop policy if exists reports_delete_all on admin_reports;
create policy reports_delete_all on admin_reports for delete using (true);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on listings to anon, authenticated;
grant select, insert, update, delete on admin_reports to anon, authenticated;
