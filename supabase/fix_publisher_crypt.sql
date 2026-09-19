-- Fix publisher password hashing on Supabase (pgcrypto lives in extensions).
-- Safe to re-run.

create extension if not exists pgcrypto with schema extensions;

create or replace function public.publisher_register(
  p_login text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  v_display text;
  v_id uuid;
  v_token uuid;
begin
  v_display := trim(coalesce(p_login, ''));
  v_key := public.normalize_publisher_login(v_display);
  if length(v_key) < 3 then
    raise exception 'LOGIN_TOO_SHORT';
  end if;
  if length(trim(coalesce(p_password, ''))) < 4 then
    raise exception 'PASSWORD_TOO_SHORT';
  end if;

  insert into publisher_accounts(login_key, password_hash, display_login)
  values (
    v_key,
    extensions.crypt(trim(p_password), extensions.gen_salt('bf')),
    v_display
  )
  returning id into v_id;

  insert into publisher_sessions(account_id)
  values (v_id)
  returning token into v_token;

  return jsonb_build_object(
    'token', v_token,
    'account_id', v_id,
    'login', v_display
  );
exception
  when unique_violation then
    raise exception 'LOGIN_TAKEN';
end;
$$;

create or replace function public.publisher_login(
  p_login text,
  p_password text
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_key text;
  rec publisher_accounts%rowtype;
  v_token uuid;
begin
  v_key := public.normalize_publisher_login(p_login);
  select * into rec from publisher_accounts where login_key = v_key;
  if not found then
    raise exception 'BAD_CREDENTIALS';
  end if;
  if rec.password_hash <> extensions.crypt(
    trim(coalesce(p_password, '')),
    rec.password_hash
  ) then
    raise exception 'BAD_CREDENTIALS';
  end if;

  delete from publisher_sessions
  where account_id = rec.id and expires_at < now();

  insert into publisher_sessions(account_id)
  values (rec.id)
  returning token into v_token;

  return jsonb_build_object(
    'token', v_token,
    'account_id', rec.id,
    'login', rec.display_login
  );
end;
$$;

grant execute on function public.publisher_register(text, text) to anon, authenticated;
grant execute on function public.publisher_login(text, text) to anon, authenticated;
