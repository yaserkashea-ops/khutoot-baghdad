-- Directory workflow for NEW submissions after go-live.
-- Existing listings are NOT deleted: any row without status is backfilled to
-- 'published' and stays visible in the public directory. Review + payment
-- apply only to requests created after this migration (default pending_review).

alter table public.listings
  add column if not exists status text;

alter table public.listings
  add column if not exists governorate text;

alter table public.listings
  add column if not exists admin_note text;

alter table public.listings
  add column if not exists reference_code text;

-- Backfill
update public.listings
set status = 'published'
where status is null or trim(status) = '';

update public.listings
set governorate = 'بغداد'
where governorate is null or trim(governorate) = '';

alter table public.listings
  alter column status set default 'pending_review';

alter table public.listings
  alter column governorate set default 'بغداد';

-- Tighten status values
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'listings_status_check'
  ) then
    alter table public.listings
      add constraint listings_status_check
      check (status in (
        'pending_review',
        'awaiting_payment',
        'published',
        'rejected'
      ));
  end if;
end $$;

create unique index if not exists listings_reference_code_uidx
  on public.listings (reference_code)
  where reference_code is not null and length(trim(reference_code)) > 0;

create index if not exists idx_listings_status
  on public.listings (status);

create index if not exists idx_listings_governorate
  on public.listings (governorate);

-- Public may only read published directory entries.
drop policy if exists listings_public_select on public.listings;
drop policy if exists listings_select_published on public.listings;
create policy listings_select_published
  on public.listings
  for select
  to anon, authenticated
  using (
    status = 'published'
    or auth.role() = 'authenticated'
  );

-- Keep public insert, but force pending via RPC preferred.
drop policy if exists listings_public_insert on public.listings;
drop policy if exists listings_insert_request on public.listings;
create policy listings_insert_request
  on public.listings
  for insert
  to anon, authenticated
  with check (
    status = 'pending_review'
    or auth.role() = 'authenticated'
  );

create or replace function public._next_listing_ref()
returns text
language plpgsql
as $$
declare
  code text;
begin
  loop
    code := 'KH-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    exit when not exists (
      select 1 from public.listings where reference_code = code
    );
  end loop;
  return code;
end;
$$;

create or replace function public.submit_listing_request(p_data jsonb)
returns public.listings
language plpgsql
security definer
set search_path = public
as $$
declare
  rec public.listings;
begin
  insert into public.listings (
    listing_type,
    area,
    destination,
    origin_subs,
    destination_subs,
    time_period,
    departure_time,
    return_time,
    vehicle_type,
    seats_count,
    gender_requirement,
    contact_phone,
    contact_telegram,
    owner_account_id,
    status,
    governorate,
    reference_code
  ) values (
    coalesce(nullif(p_data->>'listing_type', ''), 'driver'),
    trim(coalesce(p_data->>'area', '')),
    trim(coalesce(p_data->>'destination', '')),
    coalesce(
      (select array_agg(x) from jsonb_array_elements_text(coalesce(p_data->'origin_subs', '[]'::jsonb)) as x),
      '{}'::text[]
    ),
    coalesce(
      (select array_agg(x) from jsonb_array_elements_text(coalesce(p_data->'destination_subs', '[]'::jsonb)) as x),
      '{}'::text[]
    ),
    coalesce(nullif(p_data->>'time_period', ''), 'morning'),
    nullif(trim(coalesce(p_data->>'departure_time', '')), ''),
    nullif(trim(coalesce(p_data->>'return_time', '')), ''),
    nullif(trim(coalesce(p_data->>'vehicle_type', '')), ''),
    nullif(p_data->>'seats_count', '')::int,
    coalesce(nullif(p_data->>'gender_requirement', ''), 'mixed'),
    nullif(trim(coalesce(p_data->>'contact_phone', '')), ''),
    nullif(trim(coalesce(p_data->>'contact_telegram', '')), ''),
    nullif(p_data->>'owner_account_id', '')::uuid,
    'pending_review',
    coalesce(nullif(trim(p_data->>'governorate'), ''), 'بغداد'),
    public._next_listing_ref()
  )
  returning * into rec;

  return rec;
end;
$$;

create or replace function public.admin_set_listing_status(
  p_id uuid,
  p_status text,
  p_admin_note text default null
)
returns public.listings
language plpgsql
security definer
set search_path = public
as $$
declare
  rec public.listings;
  v_status text;
begin
  v_status := trim(coalesce(p_status, ''));
  if v_status not in ('pending_review', 'awaiting_payment', 'published', 'rejected') then
    raise exception 'INVALID_STATUS';
  end if;

  update public.listings
  set
    status = v_status,
    admin_note = case
      when p_admin_note is null then admin_note
      else nullif(trim(p_admin_note), '')
    end,
    bumped_at = case when v_status = 'published' then now() else bumped_at end,
    updated_at = now()
  where id = p_id
  returning * into rec;

  if not found then
    raise exception 'NOT_FOUND';
  end if;

  return rec;
end;
$$;

create or replace function public.admin_list_listings_by_status(p_status text default null)
returns setof public.listings
language sql
security definer
set search_path = public
stable
as $$
  select *
  from public.listings
  where p_status is null
     or trim(p_status) = ''
     or status = trim(p_status)
  order by
    case status
      when 'pending_review' then 0
      when 'awaiting_payment' then 1
      when 'rejected' then 2
      else 3
    end,
    created_at desc;
$$;

revoke all on function public.submit_listing_request(jsonb) from public;
grant execute on function public.submit_listing_request(jsonb) to anon, authenticated;

revoke all on function public.admin_set_listing_status(uuid, text, text) from public;
grant execute on function public.admin_set_listing_status(uuid, text, text) to authenticated;

revoke all on function public.admin_list_listings_by_status(text) from public;
grant execute on function public.admin_list_listings_by_status(text) to authenticated;

insert into public.app_settings (key, value) values
  ('publish_fee_note', 'رسوم نشر الخط تُحدَّد عبر الإدارة بعد المراجعة'),
  ('directory_title', 'دليل خطوط بغداد')
on conflict (key) do nothing;

