-- خطوط بغداد — schema v2 (secure launch)
-- Public: read + publish listings, submit reports.
-- Admin: authenticated Supabase Auth users only.

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
  owner_account_id uuid,
  view_count int not null default 0,
  bumped_at timestamptz,
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
  contact_phone text,
  contact_telegram text,
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

-- Drop legacy open policies if present.
drop policy if exists listings_select_all on listings;
drop policy if exists listings_insert_all on listings;
drop policy if exists listings_update_all on listings;
drop policy if exists listings_delete_all on listings;
drop policy if exists reports_select_all on admin_reports;
drop policy if exists reports_insert_all on admin_reports;
drop policy if exists reports_update_all on admin_reports;
drop policy if exists reports_delete_all on admin_reports;

drop policy if exists listings_public_select on listings;
drop policy if exists listings_public_insert on listings;
drop policy if exists listings_admin_update on listings;
drop policy if exists listings_admin_delete on listings;
drop policy if exists reports_public_insert on admin_reports;
drop policy if exists reports_admin_select on admin_reports;
drop policy if exists reports_admin_update on admin_reports;
drop policy if exists reports_admin_delete on admin_reports;

-- Public app
create policy listings_public_select on listings
  for select to anon, authenticated using (true);

create policy listings_public_insert on listings
  for insert to anon, authenticated with check (true);

-- Admin only (Supabase Auth session)
create policy listings_admin_update on listings
  for update to authenticated using (true) with check (true);

create policy listings_admin_delete on listings
  for delete to authenticated using (true);

create policy reports_public_insert on admin_reports
  for insert to anon, authenticated with check (true);

create policy reports_admin_select on admin_reports
  for select to authenticated using (true);

create policy reports_admin_update on admin_reports
  for update to authenticated using (true) with check (true);

create policy reports_admin_delete on admin_reports
  for delete to authenticated using (true);

grant usage on schema public to anon, authenticated;
grant select, insert on listings to anon;
grant select, insert, update, delete on listings to authenticated;
grant insert on admin_reports to anon;
grant select, insert, update, delete on admin_reports to authenticated;

-- —— إدارة المنشور عبر رقم الهاتف (بدون تسجيل دخول) ——
create or replace function public.normalize_iq_phone(p text)
returns text
language sql
immutable
as $$
  select case
    when length(d) = 0 then ''
    when d like '964%' then d
    when d like '0%' then '964' || substr(d, 2)
    when length(d) = 10 and d like '7%' then '964' || d
    else d
  end
  from (select regexp_replace(coalesce(p, ''), '\D', '', 'g') as d) s;
$$;

create or replace function public.find_listings_by_phone(p_phone text)
returns setof listings
language sql
security definer
set search_path = public
as $$
  select l.*
  from listings l
  where public.normalize_iq_phone(coalesce(l.contact_phone, '')) =
        public.normalize_iq_phone(p_phone)
    and public.normalize_iq_phone(p_phone) <> ''
  order by l.updated_at desc
  limit 10;
$$;

create or replace function public.delete_listing_by_phone(p_phone text, p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  n int;
begin
  delete from listings l
  where l.id = p_id
    and public.normalize_iq_phone(coalesce(l.contact_phone, '')) =
        public.normalize_iq_phone(p_phone)
    and public.normalize_iq_phone(p_phone) <> '';
  get diagnostics n = row_count;
  return n > 0;
end;
$$;

create or replace function public.update_listing_by_phone(
  p_phone text,
  p_id uuid,
  p_data jsonb
)
returns listings
language plpgsql
security definer
set search_path = public
as $$
declare
  rec listings;
begin
  if public.normalize_iq_phone(p_phone) = '' then
    raise exception 'رقم الهاتف غير صالح';
  end if;

  update listings l set
    listing_type = coalesce(p_data->>'listing_type', l.listing_type),
    area = coalesce(p_data->>'area', l.area),
    destination = coalesce(p_data->>'destination', l.destination),
    origin_subs = case
      when p_data ? 'origin_subs' then coalesce(
        array(select jsonb_array_elements_text(coalesce(p_data->'origin_subs', '[]'::jsonb))),
        '{}'::text[]
      )
      else l.origin_subs
    end,
    destination_subs = case
      when p_data ? 'destination_subs' then coalesce(
        array(select jsonb_array_elements_text(coalesce(p_data->'destination_subs', '[]'::jsonb))),
        '{}'::text[]
      )
      else l.destination_subs
    end,
    time_period = coalesce(p_data->>'time_period', l.time_period),
    departure_time = case
      when p_data ? 'departure_time' then nullif(p_data->>'departure_time', '')
      else l.departure_time
    end,
    return_time = case
      when p_data ? 'return_time' then nullif(p_data->>'return_time', '')
      else l.return_time
    end,
    vehicle_type = case
      when p_data ? 'vehicle_type' then nullif(p_data->>'vehicle_type', '')
      else l.vehicle_type
    end,
    seats_count = case
      when p_data ? 'seats_count' then nullif(p_data->>'seats_count', '')::int
      else l.seats_count
    end,
    gender_requirement = coalesce(p_data->>'gender_requirement', l.gender_requirement),
    contact_phone = coalesce(nullif(p_data->>'contact_phone', ''), l.contact_phone),
    contact_telegram = case
      when p_data ? 'contact_telegram' then nullif(p_data->>'contact_telegram', '')
      else l.contact_telegram
    end,
    updated_at = now()
  where l.id = p_id
    and public.normalize_iq_phone(coalesce(l.contact_phone, '')) =
        public.normalize_iq_phone(p_phone)
  returning * into rec;

  if rec.id is null then
    raise exception 'المنشور غير موجود أو رقم الهاتف غير مطابق';
  end if;
  return rec;
end;
$$;

grant execute on function public.normalize_iq_phone(text) to anon, authenticated;
grant execute on function public.find_listings_by_phone(text) to anon, authenticated;
grant execute on function public.delete_listing_by_phone(text, uuid) to anon, authenticated;
grant execute on function public.update_listing_by_phone(text, uuid, jsonb) to anon, authenticated;

-- Existing projects: add separate report contact channels (safe to re-run).
alter table admin_reports add column if not exists contact_phone text;
alter table admin_reports add column if not exists contact_telegram text;

-- —— دعوات التطبيق (أدمن فقط) ——
create table if not exists outreach_leads (
  id uuid primary key default gen_random_uuid(),
  phone text,
  telegram text,
  source_snippet text,
  status text not null default 'new'
    check (status in ('new', 'invited', 'skipped', 'opt_out')),
  last_contacted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint outreach_leads_has_contact check (
    nullif(trim(coalesce(phone, '')), '') is not null
    or nullif(trim(coalesce(telegram, '')), '') is not null
  )
);

create unique index if not exists outreach_leads_phone_uidx
  on outreach_leads (phone)
  where phone is not null and length(trim(phone)) > 0;

create unique index if not exists outreach_leads_telegram_uidx
  on outreach_leads (lower(telegram))
  where telegram is not null and length(trim(telegram)) > 0;

create index if not exists idx_outreach_leads_status on outreach_leads(status);
create index if not exists idx_outreach_leads_created_at
  on outreach_leads(created_at desc);

drop trigger if exists outreach_leads_set_updated_at on outreach_leads;
create trigger outreach_leads_set_updated_at
before update on outreach_leads
for each row execute function set_updated_at();

alter table outreach_leads enable row level security;

drop policy if exists outreach_leads_admin_select on outreach_leads;
drop policy if exists outreach_leads_admin_insert on outreach_leads;
drop policy if exists outreach_leads_admin_update on outreach_leads;
drop policy if exists outreach_leads_admin_delete on outreach_leads;

create policy outreach_leads_admin_select on outreach_leads
  for select to authenticated using (true);

create policy outreach_leads_admin_insert on outreach_leads
  for insert to authenticated with check (true);

create policy outreach_leads_admin_update on outreach_leads
  for update to authenticated using (true) with check (true);

create policy outreach_leads_admin_delete on outreach_leads
  for delete to authenticated using (true);

grant select, insert, update, delete on outreach_leads to authenticated;

-- —— حسابات الناشرين (بدون OTP) ——
-- طبّق أيضاً: migrate_publisher_accounts.sql على قاعدة موجودة.
