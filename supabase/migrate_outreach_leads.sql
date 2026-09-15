-- Outreach leads for manual invite campaigns (admin only).
-- Safe to re-run.

create table if not exists outreach_leads (
  id uuid primary key default gen_random_uuid(),
  phone text,
  telegram text,
  source_snippet text,
  status text not null default 'new'
    check (status in ('new', 'invited', 'skipped', 'opt_out')),
  last_contacted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint outreach_leads_has_contact check (
    nullif(trim(coalesce(phone, '')), '') is not null
    or nullif(trim(coalesce(telegram, '')), '') is not null
  )
);

create unique index if not exists outreach_leads_phone_uidx
  on outreach_leads (phone)
  where phone is not null and length(trim(phone)) > 0;

create unique index if not exists outreach_leads_telegram_uidx
  on outreach_leads (lower(telegram))
  where telegram is not null and length(trim(telegram)) > 0;

create index if not exists idx_outreach_leads_status on outreach_leads(status);
create index if not exists idx_outreach_leads_created_at
  on outreach_leads(created_at desc);

drop trigger if exists outreach_leads_set_updated_at on outreach_leads;
create trigger outreach_leads_set_updated_at
before update on outreach_leads
for each row execute function set_updated_at();

alter table outreach_leads enable row level security;

drop policy if exists outreach_leads_admin_select on outreach_leads;
drop policy if exists outreach_leads_admin_insert on outreach_leads;
drop policy if exists outreach_leads_admin_update on outreach_leads;
drop policy if exists outreach_leads_admin_delete on outreach_leads;

create policy outreach_leads_admin_select on outreach_leads
  for select to authenticated using (true);

create policy outreach_leads_admin_insert on outreach_leads
  for insert to authenticated with check (true);

create policy outreach_leads_admin_update on outreach_leads
  for update to authenticated using (true) with check (true);

create policy outreach_leads_admin_delete on outreach_leads
  for delete to authenticated using (true);

grant select, insert, update, delete on outreach_leads to authenticated;
