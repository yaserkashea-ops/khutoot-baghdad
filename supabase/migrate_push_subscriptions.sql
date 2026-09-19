-- Web Push subscriptions for publisher phone notifications. Safe to re-run.

create table if not exists public.publisher_push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.publisher_accounts(id) on delete cascade,
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  user_agent text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (endpoint)
);

create index if not exists idx_push_subs_account
  on public.publisher_push_subscriptions (account_id);

alter table public.publisher_push_subscriptions enable row level security;

revoke all on table public.publisher_push_subscriptions from anon, authenticated;

create or replace function public.publisher_save_push_subscription(
  p_token text,
  p_endpoint text,
  p_p256dh text,
  p_auth text,
  p_user_agent text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account uuid;
begin
  if p_token is null or length(trim(p_token)) < 8 then
    return false;
  end if;
  if p_endpoint is null or length(trim(p_endpoint)) < 12 then
    return false;
  end if;
  if p_p256dh is null or p_auth is null then
    return false;
  end if;

  select s.account_id into v_account
  from public.publisher_sessions s
  where s.token = trim(p_token)
    and s.expires_at > now()
  limit 1;

  if v_account is null then
    return false;
  end if;

  insert into public.publisher_push_subscriptions (
    account_id, endpoint, p256dh, auth, user_agent, updated_at
  ) values (
    v_account,
    trim(p_endpoint),
    trim(p_p256dh),
    trim(p_auth),
    nullif(trim(coalesce(p_user_agent, '')), ''),
    now()
  )
  on conflict (endpoint) do update
    set account_id = excluded.account_id,
        p256dh = excluded.p256dh,
        auth = excluded.auth,
        user_agent = excluded.user_agent,
        updated_at = now();

  return true;
end;
$$;

create or replace function public.publisher_delete_push_subscription(
  p_token text,
  p_endpoint text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_account uuid;
begin
  select s.account_id into v_account
  from public.publisher_sessions s
  where s.token = trim(p_token)
    and s.expires_at > now()
  limit 1;

  if v_account is null then
    return false;
  end if;

  delete from public.publisher_push_subscriptions
  where account_id = v_account
    and endpoint = trim(p_endpoint);

  return true;
end;
$$;

-- Used by Edge Function (service role) to load targets for a listing.
create or replace function public.admin_push_targets_for_listing(p_listing_id uuid)
returns table (
  endpoint text,
  p256dh text,
  auth text,
  area text,
  destination text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    s.endpoint,
    s.p256dh,
    s.auth,
    l.area,
    l.destination
  from public.listings l
  join public.publisher_push_subscriptions s
    on s.account_id = l.owner_account_id
  where l.id = p_listing_id
    and l.owner_account_id is not null;
end;
$$;

revoke all on function public.publisher_save_push_subscription(text, text, text, text, text) from public;
grant execute on function public.publisher_save_push_subscription(text, text, text, text, text) to anon, authenticated;

revoke all on function public.publisher_delete_push_subscription(text, text) from public;
grant execute on function public.publisher_delete_push_subscription(text, text) to anon, authenticated;

revoke all on function public.admin_push_targets_for_listing(uuid) from public;
grant execute on function public.admin_push_targets_for_listing(uuid) to service_role;
