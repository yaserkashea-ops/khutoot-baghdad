-- Optional publisher accounts (no OTP). Safe to re-run.
-- Separate from admin Supabase Auth.

create extension if not exists pgcrypto with schema extensions;

alter table listings
  add column if not exists owner_account_id uuid;

alter table listings
  add column if not exists view_count int not null default 0;

alter table listings
  add column if not exists bumped_at timestamptz;

create table if not exists publisher_accounts (
  id uuid primary key default gen_random_uuid(),
  login_key text not null unique,
  password_hash text not null,
  display_login text not null,
  created_at timestamptz not null default now()
);

create table if not exists publisher_sessions (
  token uuid primary key default gen_random_uuid(),
  account_id uuid not null references publisher_accounts(id) on delete cascade,
  expires_at timestamptz not null default (now() + interval '180 days'),
  created_at timestamptz not null default now()
);

create index if not exists idx_publisher_sessions_account
  on publisher_sessions(account_id);

create index if not exists idx_listings_owner_account
  on listings(owner_account_id);

create index if not exists idx_listings_bumped_at
  on listings(bumped_at desc nulls last);

create or replace function public.normalize_publisher_login(p_login text)
returns text
language plpgsql
immutable
as $$
declare
  s text;
  digits text;
begin
  s := lower(trim(coalesce(p_login, '')));
  digits := regexp_replace(s, '[^0-9]', '', 'g');
  if length(digits) >= 8 then
    return digits;
  end if;
  return s;
end;
$$;

create or replace function public.publisher_register(
  p_login text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  v_display text;
  v_id uuid;
  v_token uuid;
begin
  v_display := trim(coalesce(p_login, ''));
  v_key := public.normalize_publisher_login(v_display);
  if length(v_key) < 3 then
    raise exception 'LOGIN_TOO_SHORT';
  end if;
  if length(trim(coalesce(p_password, ''))) < 4 then
    raise exception 'PASSWORD_TOO_SHORT';
  end if;

  insert into publisher_accounts(login_key, password_hash, display_login)
  values (
    v_key,
    extensions.crypt(trim(p_password), extensions.gen_salt('bf')),
    v_display
  )
  returning id into v_id;

  insert into publisher_sessions(account_id)
  values (v_id)
  returning token into v_token;

  return jsonb_build_object(
    'token', v_token,
    'account_id', v_id,
    'login', v_display
  );
exception
  when unique_violation then
    raise exception 'LOGIN_TAKEN';
end;
$$;

create or replace function public.publisher_login(
  p_login text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  rec publisher_accounts%rowtype;
  v_token uuid;
begin
  v_key := public.normalize_publisher_login(p_login);
  select * into rec from publisher_accounts where login_key = v_key;
  if not found then
    raise exception 'BAD_CREDENTIALS';
  end if;
  if rec.password_hash <> extensions.crypt(
    trim(coalesce(p_password, '')),
    rec.password_hash
  ) then
    raise exception 'BAD_CREDENTIALS';
  end if;

  delete from publisher_sessions
  where account_id = rec.id and expires_at < now();

  insert into publisher_sessions(account_id)
  values (rec.id)
  returning token into v_token;

  return jsonb_build_object(
    'token', v_token,
    'account_id', rec.id,
    'login', rec.display_login
  );
end;
$$;

create or replace function public.publisher_account_from_token(p_token uuid)
returns uuid
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  select account_id into v_id
  from publisher_sessions
  where token = p_token and expires_at > now();
  return v_id;
end;
$$;

create or replace function public.publisher_my_listings(p_token uuid)
returns setof listings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  v_id := public.publisher_account_from_token(p_token);
  if v_id is null then
    raise exception 'SESSION_EXPIRED';
  end if;
  return query
    select *
    from listings l
    where l.owner_account_id = v_id
    order by coalesce(l.bumped_at, l.created_at) desc;
end;
$$;

create or replace function public.publisher_claim_listing(
  p_token uuid,
  p_listing_id uuid
)
returns listings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  rec listings;
  v_count int;
begin
  v_id := public.publisher_account_from_token(p_token);
  if v_id is null then
    raise exception 'SESSION_EXPIRED';
  end if;

  -- Already owned by this account: allow (idempotent).
  select * into rec
  from listings l
  where l.id = p_listing_id and l.owner_account_id = v_id;
  if found then
    return rec;
  end if;

  select count(*)::int into v_count
  from listings
  where owner_account_id = v_id;
  if coalesce(v_count, 0) >= 3 then
    raise exception 'LISTING_LIMIT';
  end if;

  update listings l
  set owner_account_id = v_id,
      updated_at = now()
  where l.id = p_listing_id
    and l.owner_account_id is null
  returning * into rec;

  if rec.id is null then
    raise exception 'LISTING_NOT_FOUND';
  end if;
  return rec;
end;
$$;

create or replace function public.publisher_delete_listing(
  p_token uuid,
  p_listing_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  v_id := public.publisher_account_from_token(p_token);
  if v_id is null then
    raise exception 'SESSION_EXPIRED';
  end if;
  delete from listings l
  where l.id = p_listing_id and l.owner_account_id = v_id;
  return found;
end;
$$;

create or replace function public.publisher_republish_listing(
  p_token uuid,
  p_listing_id uuid
)
returns listings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  rec listings;
begin
  v_id := public.publisher_account_from_token(p_token);
  if v_id is null then
    raise exception 'SESSION_EXPIRED';
  end if;

  update listings l
  set bumped_at = now(),
      updated_at = now()
  where l.id = p_listing_id and l.owner_account_id = v_id
  returning * into rec;

  if rec.id is null then
    raise exception 'LISTING_NOT_FOUND';
  end if;
  return rec;
end;
$$;

create or replace function public.increment_listing_views(p_listing_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  update listings
  set view_count = coalesce(view_count, 0) + 1
  where id = p_listing_id
  returning view_count into v_count;
  return coalesce(v_count, 0);
end;
$$;

create or replace function public.publisher_update_listing(
  p_token uuid,
  p_listing_id uuid,
  p_data jsonb
)
returns listings
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  rec listings;
begin
  v_id := public.publisher_account_from_token(p_token);
  if v_id is null then
    raise exception 'SESSION_EXPIRED';
  end if;

  update listings l set
    listing_type = coalesce(p_data->>'listing_type', l.listing_type),
    area = coalesce(p_data->>'area', l.area),
    destination = coalesce(p_data->>'destination', l.destination),
    origin_subs = case
      when p_data ? 'origin_subs' then (
        select coalesce(array_agg(x), '{}')
        from jsonb_array_elements_text(p_data->'origin_subs') as x
      )
      else l.origin_subs
    end,
    destination_subs = case
      when p_data ? 'destination_subs' then (
        select coalesce(array_agg(x), '{}')
        from jsonb_array_elements_text(p_data->'destination_subs') as x
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
    contact_phone = case
      when p_data ? 'contact_phone' then nullif(p_data->>'contact_phone', '')
      else l.contact_phone
    end,
    contact_telegram = case
      when p_data ? 'contact_telegram' then nullif(p_data->>'contact_telegram', '')
      else l.contact_telegram
    end,
    updated_at = now()
  where l.id = p_listing_id and l.owner_account_id = v_id
  returning * into rec;

  if rec.id is null then
    raise exception 'LISTING_NOT_FOUND';
  end if;
  return rec;
end;
$$;

grant execute on function public.publisher_update_listing(uuid, uuid, jsonb) to anon, authenticated;
grant execute on function public.publisher_register(text, text) to anon, authenticated;
grant execute on function public.publisher_login(text, text) to anon, authenticated;
grant execute on function public.publisher_account_from_token(uuid) to anon, authenticated;
grant execute on function public.publisher_my_listings(uuid) to anon, authenticated;
grant execute on function public.publisher_claim_listing(uuid, uuid) to anon, authenticated;
grant execute on function public.publisher_delete_listing(uuid, uuid) to anon, authenticated;
grant execute on function public.publisher_republish_listing(uuid, uuid) to anon, authenticated;
grant execute on function public.increment_listing_views(uuid) to anon, authenticated;

-- No direct table access; all auth goes through security definer RPCs.
alter table publisher_accounts enable row level security;
alter table publisher_sessions enable row level security;
revoke all on publisher_accounts from anon, authenticated;
revoke all on publisher_sessions from anon, authenticated;

-- Admin dashboard counts (authenticated only).
create or replace function public.admin_publisher_stats()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total int;
  v_drivers int;
  v_riders int;
begin
  select count(*)::int into v_total from publisher_accounts;

  select count(distinct owner_account_id)::int into v_drivers
  from listings
  where owner_account_id is not null
    and listing_type = 'driver';

  select count(distinct owner_account_id)::int into v_riders
  from listings
  where owner_account_id is not null
    and listing_type = 'rider';

  return jsonb_build_object(
    'accounts_total', coalesce(v_total, 0),
    'accounts_drivers', coalesce(v_drivers, 0),
    'accounts_riders', coalesce(v_riders, 0)
  );
end;
$$;

revoke all on function public.admin_publisher_stats() from public;
grant execute on function public.admin_publisher_stats() to authenticated;
