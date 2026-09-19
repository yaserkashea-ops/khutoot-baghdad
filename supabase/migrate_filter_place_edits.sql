-- Editable filter places: rename/hide catalog names + update managed places.
-- Safe to re-run. Run after migrate_managed_places.sql.

create table if not exists public.filter_place_overrides (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  renamed_to text,
  hidden boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint filter_place_overrides_has_change check (
    hidden = true
    or (renamed_to is not null and length(trim(renamed_to)) >= 2)
  )
);

create unique index if not exists filter_place_overrides_name_uidx
  on public.filter_place_overrides (lower(trim(name)));

alter table public.filter_place_overrides enable row level security;

drop policy if exists filter_place_overrides_select on public.filter_place_overrides;
create policy filter_place_overrides_select
  on public.filter_place_overrides
  for select
  to anon, authenticated
  using (true);

drop policy if exists filter_place_overrides_admin_all on public.filter_place_overrides;
create policy filter_place_overrides_admin_all
  on public.filter_place_overrides
  for all
  to authenticated
  using (true)
  with check (true);

grant select on public.filter_place_overrides to anon, authenticated;
grant insert, update, delete on public.filter_place_overrides to authenticated;

create or replace function public.list_filter_place_overrides()
returns setof public.filter_place_overrides
language sql
security definer
set search_path = public
stable
as $$
  select * from public.filter_place_overrides
  order by updated_at desc;
$$;

create or replace function public.admin_upsert_filter_place_override(
  p_name text,
  p_renamed_to text default null,
  p_hidden boolean default false
)
returns public.filter_place_overrides
language plpgsql
security definer
set search_path = public
as $$
declare
  v_name text;
  v_renamed text;
  rec public.filter_place_overrides;
begin
  v_name := trim(coalesce(p_name, ''));
  v_renamed := nullif(trim(coalesce(p_renamed_to, '')), '');

  if length(v_name) < 2 then
    raise exception 'INVALID_NAME';
  end if;
  if v_renamed is not null and length(v_renamed) > 60 then
    raise exception 'NAME_TOO_LONG';
  end if;
  if p_hidden is not true and v_renamed is null then
    raise exception 'NO_CHANGE';
  end if;

  select * into rec
  from public.filter_place_overrides
  where lower(trim(name)) = lower(v_name)
  limit 1;

  if found then
    update public.filter_place_overrides
    set
      renamed_to = v_renamed,
      hidden = coalesce(p_hidden, false),
      updated_at = now()
    where id = rec.id
    returning * into rec;
    return rec;
  end if;

  insert into public.filter_place_overrides (name, renamed_to, hidden)
  values (v_name, v_renamed, coalesce(p_hidden, false))
  returning * into rec;

  return rec;
end;
$$;

create or replace function public.admin_delete_filter_place_override(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.filter_place_overrides where id = p_id;
  return found;
end;
$$;

create or replace function public.admin_clear_filter_place_override_by_name(p_name text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.filter_place_overrides
  where lower(trim(name)) = lower(trim(p_name));
  return found;
end;
$$;

create or replace function public.admin_update_managed_place(
  p_id uuid,
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
  clash public.managed_places;
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

  select * into clash
  from public.managed_places
  where lower(trim(name)) = lower(v_name)
    and id <> p_id
  limit 1;
  if found then
    raise exception 'NAME_EXISTS';
  end if;

  update public.managed_places
  set
    name = v_name,
    kind = v_kind,
    active = true,
    updated_at = now()
  where id = p_id
  returning * into rec;

  if not found then
    raise exception 'NOT_FOUND';
  end if;

  return rec;
end;
$$;

revoke all on function public.list_filter_place_overrides() from public;
grant execute on function public.list_filter_place_overrides() to anon, authenticated;

revoke all on function public.admin_upsert_filter_place_override(text, text, boolean) from public;
grant execute on function public.admin_upsert_filter_place_override(text, text, boolean) to authenticated;

revoke all on function public.admin_delete_filter_place_override(uuid) from public;
grant execute on function public.admin_delete_filter_place_override(uuid) to authenticated;

revoke all on function public.admin_clear_filter_place_override_by_name(text) from public;
grant execute on function public.admin_clear_filter_place_override_by_name(text) to authenticated;

revoke all on function public.admin_update_managed_place(uuid, text, text) from public;
grant execute on function public.admin_update_managed_place(uuid, text, text) to authenticated;
