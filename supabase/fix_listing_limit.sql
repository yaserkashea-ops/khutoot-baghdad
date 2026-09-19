-- Enforce max 3 active listings per publisher account. Safe to re-run.

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

grant execute on function public.publisher_claim_listing(uuid, uuid) to anon, authenticated;
