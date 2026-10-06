-- Keep published listings in the directory after 30 days.
-- Nothing is auto-deleted; admin removes posts from the control panel.

drop policy if exists listings_select_published on public.listings;
create policy listings_select_published
  on public.listings
  for select
  to anon, authenticated
  using (
    (
      status = 'published'
      and coalesce(is_hidden, false) = false
    )
    or auth.role() = 'authenticated'
  );
