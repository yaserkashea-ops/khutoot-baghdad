-- 30-day directory subscription window.
-- Safe to re-run. Existing published rows get expires_at from bumped_at/created_at + 30 days.

alter table public.listings
  add column if not exists expires_at timestamptz;

alter table public.listings
  add column if not exists is_hidden boolean;

update public.listings
set is_hidden = false
where is_hidden is null;

alter table public.listings
  alter column is_hidden set default false;

-- Backfill expiry for published (and any row missing expires_at).
update public.listings
set expires_at = coalesce(bumped_at, created_at, now()) + interval '30 days'
where expires_at is null;

create index if not exists idx_listings_expires_at
  on public.listings (expires_at);

create index if not exists idx_listings_is_hidden
  on public.listings (is_hidden);

-- Public directory: published, not hidden, not expired.
drop policy if exists listings_select_published on public.listings;
create policy listings_select_published
  on public.listings
  for select
  to anon, authenticated
  using (
    (
      status = 'published'
      and coalesce(is_hidden, false) = false
      and (expires_at is null or expires_at > now())
    )
    or auth.role() = 'authenticated'
  );

-- When admin publishes: start a fresh 30-day window.
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
    expires_at = case
      when v_status = 'published' then now() + interval '30 days'
      else expires_at
    end,
    is_hidden = case when v_status = 'published' then false else is_hidden end,
    updated_at = now()
  where id = p_id
  returning * into rec;

  if not found then
    raise exception 'NOT_FOUND';
  end if;

  return rec;
end;
$$;

create or replace function public.admin_renew_listing(p_id uuid)
returns public.listings
language plpgsql
security definer
set search_path = public
as $$
declare
  rec public.listings;
begin
  update public.listings
  set
    status = 'published',
    is_hidden = false,
    bumped_at = now(),
    expires_at = now() + interval '30 days',
    updated_at = now()
  where id = p_id
  returning * into rec;

  if not found then
    raise exception 'NOT_FOUND';
  end if;

  return rec;
end;
$$;

create or replace function public.admin_hide_listing(p_id uuid)
returns public.listings
language plpgsql
security definer
set search_path = public
as $$
declare
  rec public.listings;
begin
  update public.listings
  set
    is_hidden = true,
    updated_at = now()
  where id = p_id
  returning * into rec;

  if not found then
    raise exception 'NOT_FOUND';
  end if;

  return rec;
end;
$$;

revoke all on function public.admin_renew_listing(uuid) from public;
grant execute on function public.admin_renew_listing(uuid) to authenticated;

revoke all on function public.admin_hide_listing(uuid) from public;
grant execute on function public.admin_hide_listing(uuid) to authenticated;

insert into public.app_settings (key, value) values
  ('subscription_days', '30'),
  (
    'subscription_expiry_wa_template',
    'مرحباً، نود إبلاغك بأن اشتراك خطك في دليل خطوط بغداد قد انتهى أو أوشك على الانتهاء. لتجديد الظهور لمدة 30 يوماً يُرجى إتمام رسوم التجديد.'
  )
on conflict (key) do nothing;
