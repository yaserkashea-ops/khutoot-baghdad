-- Ensure listing view counters work for anonymous directory traffic.
-- Safe to re-run.
-- Array elements are counted with multiplicity (duplicate ids = multiple views).

alter table public.listings
  add column if not exists view_count int not null default 0;

create or replace function public.increment_listing_views(p_listing_id uuid)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count int;
begin
  update public.listings
  set view_count = coalesce(view_count, 0) + 1
  where id = p_listing_id
    and coalesce(is_hidden, false) = false
    and coalesce(status, 'published') = 'published'
  returning view_count into v_count;
  return coalesce(v_count, 0);
end;
$$;

create or replace function public.increment_listing_views_many(p_ids uuid[])
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  v_n int := 0;
begin
  if p_ids is null or array_length(p_ids, 1) is null then
    return 0;
  end if;

  -- Count each array element (same listing can appear more than once).
  update public.listings l
  set view_count = coalesce(l.view_count, 0) + s.cnt
  from (
    select id, count(*)::int as cnt
    from unnest(p_ids) as id
    group by id
  ) s
  where l.id = s.id
    and coalesce(l.is_hidden, false) = false
    and coalesce(l.status, 'published') = 'published';

  get diagnostics v_n = row_count;
  return coalesce(v_n, 0);
end;
$$;

revoke all on function public.increment_listing_views(uuid) from public;
revoke all on function public.increment_listing_views_many(uuid[]) from public;
grant execute on function public.increment_listing_views(uuid) to anon, authenticated;
grant execute on function public.increment_listing_views_many(uuid[]) to anon, authenticated;
