-- Public directory open counter: real link/app opens only. Safe to re-run.
-- Historical clicks before this counter did not exist in our DB — do not invent them.

create table if not exists public.directory_activity (
  id int primary key default 1 check (id = 1),
  open_count bigint not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.directory_activity (id, open_count)
values (1, 0)
on conflict (id) do nothing;

alter table public.directory_activity enable row level security;

revoke all on table public.directory_activity from anon, authenticated;

create or replace function public.record_directory_open()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count bigint;
begin
  insert into public.directory_activity (id, open_count, updated_at)
  values (1, 1, now())
  on conflict (id) do update
    set open_count = public.directory_activity.open_count + 1,
        updated_at = now()
  returning open_count into v_count;

  return coalesce(v_count, 0);
end;
$$;

create or replace function public.get_directory_open_count()
returns bigint
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(
    (select open_count from public.directory_activity where id = 1),
    0
  );
$$;

-- Optional admin baseline when a real external click total is known
-- (Search Console / hosting analytics / short-link stats). Never auto-guess.
create or replace function public.set_directory_open_count(p_count bigint)
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count bigint;
begin
  if p_count is null or p_count < 0 then
    return public.get_directory_open_count();
  end if;

  insert into public.directory_activity (id, open_count, updated_at)
  values (1, p_count, now())
  on conflict (id) do update
    set open_count = p_count,
        updated_at = now()
  returning open_count into v_count;

  return coalesce(v_count, 0);
end;
$$;

-- Drop the old approximate seeder if it exists.
drop function if exists public.seed_directory_opens_from_history();

revoke all on function public.record_directory_open() from public;
grant execute on function public.record_directory_open() to anon, authenticated;

revoke all on function public.get_directory_open_count() from public;
grant execute on function public.get_directory_open_count() to anon, authenticated;

revoke all on function public.set_directory_open_count(bigint) from public;
grant execute on function public.set_directory_open_count(bigint) to authenticated;

-- Operator baseline: prior link clicks. New opens keep incrementing from here.
insert into public.directory_activity (id, open_count, updated_at)
values (1, 26975, now())
on conflict (id) do update
  set open_count = greatest(public.directory_activity.open_count, 26975),
      updated_at = now();
