-- Editable public contact channels (WhatsApp / Telegram). Safe to re-run.

create table if not exists public.app_settings (
  key text primary key,
  value text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.app_settings enable row level security;

drop policy if exists app_settings_select on public.app_settings;
create policy app_settings_select
  on public.app_settings
  for select
  to anon, authenticated
  using (true);

drop policy if exists app_settings_admin_write on public.app_settings;
create policy app_settings_admin_write
  on public.app_settings
  for all
  to authenticated
  using (true)
  with check (true);

grant select on public.app_settings to anon, authenticated;
grant insert, update, delete on public.app_settings to authenticated;

insert into public.app_settings (key, value) values
  ('whatsapp_phone', '9647760000989'),
  ('telegram', 'https://t.me/Opal10')
on conflict (key) do nothing;

create or replace function public.get_app_settings()
returns jsonb
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(jsonb_object_agg(key, value), '{}'::jsonb)
  from public.app_settings;
$$;

create or replace function public.admin_set_app_setting(
  p_key text,
  p_value text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_key is null or length(trim(p_key)) < 2 then
    return false;
  end if;
  insert into public.app_settings (key, value, updated_at)
  values (trim(p_key), coalesce(p_value, ''), now())
  on conflict (key) do update
    set value = excluded.value, updated_at = now();
  return true;
end;
$$;

revoke all on function public.get_app_settings() from public;
grant execute on function public.get_app_settings() to anon, authenticated;

revoke all on function public.admin_set_app_setting(text, text) from public;
grant execute on function public.admin_set_app_setting(text, text) to authenticated;
