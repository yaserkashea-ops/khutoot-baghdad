-- Run once in Supabase SQL Editor so new report contact fields exist.
alter table admin_reports add column if not exists contact_phone text;
alter table admin_reports add column if not exists contact_telegram text;
