-- Live unification follow-up. Safe to re-run.
-- Does not delete listings. Adds missing booking column and keeps published
-- posts visible after 30 days (admin removes them from the control panel).

alter table public.listings
  add column if not exists route_details text;

alter table public.listings
  add column if not exists is_booked boolean;

update public.listings
set is_booked = false
where is_booked is null;

alter table public.listings
  alter column is_booked set default false;

create table if not exists public.contact_unlocks (
  id uuid primary key default gen_random_uuid(),
  rider_request_id uuid not null references public.listings(id) on delete cascade,
  driver_account_id uuid,
  driver_contact text not null,
  status text not null default 'pending'
    check (status in ('pending','approved','rejected')),
  requested_at timestamptz not null default now(),
  approved_at timestamptz
);

create unique index if not exists contact_unlocks_request_driver_uidx
  on public.contact_unlocks (rider_request_id, driver_contact);

create unique index if not exists contact_unlocks_one_active_booking
  on public.contact_unlocks (rider_request_id)
  where status in ('pending', 'approved');

create index if not exists contact_unlocks_status_requested_idx
  on public.contact_unlocks (status, requested_at desc);

alter table public.contact_unlocks enable row level security;

drop policy if exists contact_unlocks_public_select on public.contact_unlocks;
drop policy if exists contact_unlocks_public_insert on public.contact_unlocks;
drop policy if exists contact_unlocks_public_update on public.contact_unlocks;
drop policy if exists contact_unlocks_admin_all on public.contact_unlocks;

create policy contact_unlocks_public_select on public.contact_unlocks
  for select to anon, authenticated using (true);

create policy contact_unlocks_public_insert on public.contact_unlocks
  for insert to anon, authenticated with check (status = 'pending');

create policy contact_unlocks_public_update on public.contact_unlocks
  for update to anon, authenticated using (true) with check (true);

create policy contact_unlocks_admin_all on public.contact_unlocks
  for all to authenticated using (true) with check (true);

grant select, insert, update on public.contact_unlocks to anon;
grant select, insert, update, delete on public.contact_unlocks to authenticated;

drop policy if exists listings_select_published on public.listings;
create policy listings_select_published
  on public.listings
  for select
  to anon, authenticated
  using (
    (
      status = 'published'
      and coalesce(is_hidden, false) = false
    )
    or auth.role() = 'authenticated'
  );
