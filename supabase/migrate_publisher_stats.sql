-- Admin stats for optional publisher accounts. Safe to re-run.

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
