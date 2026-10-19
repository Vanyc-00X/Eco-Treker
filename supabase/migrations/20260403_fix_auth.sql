-- Fix: "Database error saving new user" + phone OTP without SMS provider
-- Run in SQL Editor after 20260401_tz_full.sql

-- ---------------------------------------------------------------------------
-- 1. Remove broken AFTER INSERT auto-confirm (UPDATE auth.users → 500 on signup)
-- ---------------------------------------------------------------------------
drop trigger if exists on_auth_user_auto_confirm on auth.users;
drop trigger if exists on_auth_user_auto_confirm_before on auth.users;
drop function if exists public.auto_confirm_auth_user() cascade;
drop function if exists public.auto_confirm_auth_user_before() cascade;

-- BEFORE INSERT: mark email confirmed without recursive UPDATE
create or replace function public.auto_confirm_auth_user_before()
returns trigger
language plpgsql
security definer
set search_path = auth, public
as $$
begin
  if new.email is not null and new.email_confirmed_at is null then
    new.email_confirmed_at := now();
  end if;
  -- Phone users also get a synthetic email; confirm phone if present
  if new.phone is not null and new.phone_confirmed_at is null then
    new.phone_confirmed_at := now();
  end if;
  return new;
end;
$$;

create trigger on_auth_user_auto_confirm_before
  before insert on auth.users
  for each row
  execute function public.auto_confirm_auth_user_before();

-- Confirm existing users so they can sign in now
update auth.users
set email_confirmed_at = coalesce(email_confirmed_at, now())
where email_confirmed_at is null and email is not null;

-- ---------------------------------------------------------------------------
-- 2. Safe profile trigger (never break signup)
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id, email, full_name, phone, qr_token, qr_token_rotated_at, verified
  ) values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'full_name', 'Student'),
    nullif(coalesce(new.phone, new.raw_user_meta_data->>'phone'), ''),
    encode(gen_random_bytes(24), 'hex'),
    now(),
    false
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(nullif(excluded.full_name, ''), public.profiles.full_name),
    phone = coalesce(excluded.phone, public.profiles.phone);
  return new;
exception when others then
  -- Never fail auth.users insert because of profile issues
  raise warning 'handle_new_user failed: %', sqlerrm;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 3. Phone OTP table + RPCs (works without Twilio)
-- ---------------------------------------------------------------------------
create table if not exists public.phone_otps (
  phone text primary key,
  code text not null,
  attempts integer not null default 0,
  locked_until timestamptz,
  expires_at timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table public.phone_otps enable row level security;
-- no direct client access; only via RPC

create or replace function public.request_phone_otp(p_phone text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9+]', '', 'g');
  v_code text;
  v_locked timestamptz;
begin
  if length(regexp_replace(v_phone, '\D', '', 'g')) < 10 then
    raise exception 'Invalid phone';
  end if;

  select locked_until into v_locked from public.phone_otps where phone = v_phone;
  if v_locked is not null and v_locked > now() then
    raise exception 'Too many attempts. Try later.';
  end if;

  v_code := lpad((floor(random() * 1000000))::int::text, 6, '0');

  insert into public.phone_otps (phone, code, attempts, locked_until, expires_at, updated_at)
  values (v_phone, v_code, 0, null, now() + interval '10 minutes', now())
  on conflict (phone) do update set
    code = excluded.code,
    attempts = 0,
    locked_until = null,
    expires_at = excluded.expires_at,
    updated_at = now();

  -- Return code so the app can show it when SMS provider is not configured.
  return v_code;
end;
$$;

create or replace function public.verify_phone_otp(p_phone text, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9+]', '', 'g');
  v_row public.phone_otps;
begin
  select * into v_row from public.phone_otps where phone = v_phone for update;
  if not found then
    raise exception 'Code not requested';
  end if;
  if v_row.locked_until is not null and v_row.locked_until > now() then
    raise exception 'Too many attempts. Try later.';
  end if;
  if v_row.expires_at < now() then
    raise exception 'Code expired';
  end if;
  if v_row.code <> trim(p_code) then
    update public.phone_otps set
      attempts = attempts + 1,
      locked_until = case when attempts + 1 >= 5 then now() + interval '15 minutes' else locked_until end,
      updated_at = now()
    where phone = v_phone;
    raise exception 'Invalid code';
  end if;

  delete from public.phone_otps where phone = v_phone;
  return true;
end;
$$;

grant execute on function public.request_phone_otp(text) to anon, authenticated;
grant execute on function public.verify_phone_otp(text, text) to anon, authenticated;

select 'auth fix ready' as status;
