-- Track PWA installs for admin dashboard. Safe to re-run.

create table if not exists public.app_installs (
  id uuid primary key default gen_random_uuid(),
  install_key text not null unique,
  platform text not null default 'unknown'
    check (platform in ('phone', 'desktop', 'unknown')),
  source text not null default 'app'
    check (source in ('app', 'admin')),
  user_agent text,
  created_at timestamptz not null default now()
);

create index if not exists idx_app_installs_platform
  on public.app_installs (platform);

create index if not exists idx_app_installs_source
  on public.app_installs (source);

alter table public.app_installs enable row level security;

create or replace function public.record_app_install(
  p_install_key text,
  p_platform text default 'unknown',
  p_source text default 'app',
  p_user_agent text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_platform text;
  v_source text;
  v_inserted int := 0;
begin
  if p_install_key is null or length(trim(p_install_key)) < 8 then
    return false;
  end if;

  v_platform := case
    when p_platform in ('phone', 'desktop', 'unknown') then p_platform
    else 'unknown'
  end;
  -- Prefer phone when UA clearly looks mobile (avoids desktop mis-labels).
  if coalesce(p_user_agent, '') ~* '(Android|iPhone|iPad|iPod|Mobile|webOS|BlackBerry|IEMobile|Opera Mini)' then
    v_platform := 'phone';
  end if;
  v_source := case
    when p_source in ('app', 'admin') then p_source
    else 'app'
  end;

  insert into public.app_installs (install_key, platform, source, user_agent)
  values (trim(p_install_key), v_platform, v_source, nullif(trim(coalesce(p_user_agent, '')), ''))
  on conflict (install_key) do nothing;

  get diagnostics v_inserted = row_count;
  return v_inserted > 0;
end;
$$;

create or replace function public.admin_app_install_stats()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone int;
  v_desktop int;
  v_total int;
begin
  select count(*)::int into v_phone
  from public.app_installs
  where platform = 'phone' and source = 'app';

  select count(*)::int into v_desktop
  from public.app_installs
  where platform = 'desktop' and source = 'app';

  select count(*)::int into v_total
  from public.app_installs
  where source = 'app';

  return jsonb_build_object(
    'phone_installs', coalesce(v_phone, 0),
    'desktop_installs', coalesce(v_desktop, 0),
    'total_installs', coalesce(v_total, 0)
  );
end;
$$;

revoke all on function public.record_app_install(text, text, text, text) from public;
grant execute on function public.record_app_install(text, text, text, text) to anon, authenticated;

revoke all on function public.admin_app_install_stats() from public;
grant execute on function public.admin_app_install_stats() to anon, authenticated;
