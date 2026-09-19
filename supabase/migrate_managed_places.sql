-- Admin-managed places (extra areas/destinations for filters + publish).
-- Safe to re-run.

create table if not exists public.managed_places (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null default 'both'
    check (kind in ('area', 'destination', 'both')),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists managed_places_name_uidx
  on public.managed_places (lower(trim(name)));

create index if not exists managed_places_active_idx
  on public.managed_places (active);

alter table public.managed_places enable row level security;

drop policy if exists managed_places_select_active on public.managed_places;
create policy managed_places_select_active
  on public.managed_places
  for select
  to anon, authenticated
  using (active = true);

drop policy if exists managed_places_admin_all on public.managed_places;
create policy managed_places_admin_all
  on public.managed_places
  for all
  to authenticated
  using (true)
  with check (true);

grant select on public.managed_places to anon, authenticated;
grant insert, update, delete on public.managed_places to authenticated;

create or replace function public.list_managed_places()
returns setof public.managed_places
language sql
security definer
set search_path = public
stable
as $$
  select *
  from public.managed_places
  where active = true
  order by created_at desc;
$$;

create or replace function public.admin_list_managed_places()
returns setof public.managed_places
language sql
security definer
set search_path = public
stable
as $$
  select *
  from public.managed_places
  order by created_at desc;
$$;

create or replace function public.admin_add_managed_place(
  p_name text,
  p_kind text default 'both'
)
returns public.managed_places
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_kind text;
  rec public.managed_places;
begin
  v_name := trim(coalesce(p_name, ''));
  if length(v_name) < 2 then
    raise exception 'INVALID_NAME';
  end if;
  if length(v_name) > 60 then
    raise exception 'NAME_TOO_LONG';
  end if;

  v_kind := case
    when p_kind in ('area', 'destination', 'both') then p_kind
    else 'both'
  end;

  select * into rec
  from public.managed_places
  where lower(trim(name)) = lower(v_name)
  limit 1;

  if found then
    update public.managed_places
    set kind = v_kind, active = true, updated_at = now(), name = v_name
    where id = rec.id
    returning * into rec;
    return rec;
  end if;

  insert into public.managed_places (name, kind, active)
  values (v_name, v_kind, true)
  returning * into rec;

  return rec;
end;
$$;

create or replace function public.admin_deactivate_managed_place(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.managed_places
  set active = false, updated_at = now()
  where id = p_id;
  return found;
end;
$$;

create or replace function public.admin_delete_managed_place(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.managed_places where id = p_id;
  return found;
end;
$$;

revoke all on function public.list_managed_places() from public;
grant execute on function public.list_managed_places() to anon, authenticated;

revoke all on function public.admin_list_managed_places() from public;
grant execute on function public.admin_list_managed_places() to authenticated;

revoke all on function public.admin_add_managed_place(text, text) from public;
grant execute on function public.admin_add_managed_place(text, text) to authenticated;

revoke all on function public.admin_deactivate_managed_place(uuid) from public;
grant execute on function public.admin_deactivate_managed_place(uuid) to authenticated;

revoke all on function public.admin_delete_managed_place(uuid) from public;
grant execute on function public.admin_delete_managed_place(uuid) to authenticated;
