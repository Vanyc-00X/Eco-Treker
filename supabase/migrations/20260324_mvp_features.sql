-- Campus Eco-Tracker: redeem, bin reports, rotatable QR tokens
-- Apply in Supabase SQL Editor after base schema.

create extension if not exists pgcrypto;

-- Rotatable Eco-ID token on profiles
alter table public.profiles
  add column if not exists qr_token text;
alter table public.profiles
  add column if not exists qr_token_rotated_at timestamptz;

create unique index if not exists profiles_qr_token_uidx
  on public.profiles (qr_token)
  where qr_token is not null;

-- Reward redemption requests
create table if not exists public.redeem_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  reward_code text not null,
  reward_title text not null,
  points_cost integer not null check (points_cost > 0),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'fulfilled')),
  created_at timestamptz not null default now()
);

create index if not exists redeem_requests_student_idx
  on public.redeem_requests (student_id, created_at desc);

alter table public.redeem_requests enable row level security;

drop policy if exists "Students insert own redeem requests" on public.redeem_requests;
create policy "Students insert own redeem requests"
  on public.redeem_requests for insert
  to authenticated
  with check (student_id = auth.uid());

drop policy if exists "Students read own redeem requests" on public.redeem_requests;
create policy "Students read own redeem requests"
  on public.redeem_requests for select
  to authenticated
  using (student_id = auth.uid());

-- Full-bin reports from map
create table if not exists public.bin_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  collection_point_id uuid not null references public.collection_points (id) on delete cascade,
  note text,
  status text not null default 'open'
    check (status in ('open', 'acknowledged', 'resolved')),
  created_at timestamptz not null default now()
);

create index if not exists bin_reports_point_idx
  on public.bin_reports (collection_point_id, created_at desc);

alter table public.bin_reports enable row level security;

drop policy if exists "Students insert bin reports" on public.bin_reports;
create policy "Students insert bin reports"
  on public.bin_reports for insert
  to authenticated
  with check (reporter_id = auth.uid());

drop policy if exists "Students read own bin reports" on public.bin_reports;
create policy "Students read own bin reports"
  on public.bin_reports for select
  to authenticated
  using (reporter_id = auth.uid());

-- Atomic redeem: deduct points + create request
create or replace function public.redeem_reward(
  p_reward_code text,
  p_reward_title text,
  p_points_cost integer
)
returns public.redeem_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_points integer;
  v_row public.redeem_requests;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;
  if p_points_cost is null or p_points_cost <= 0 then
    raise exception 'Invalid points cost';
  end if;

  select green_points into v_points
  from public.profiles
  where id = v_uid
  for update;

  if v_points is null then
    raise exception 'Profile not found';
  end if;
  if v_points < p_points_cost then
    raise exception 'Недостаточно баллов';
  end if;

  update public.profiles
  set green_points = green_points - p_points_cost
  where id = v_uid;

  insert into public.redeem_requests (
    student_id, reward_code, reward_title, points_cost, status
  ) values (
    v_uid, p_reward_code, p_reward_title, p_points_cost, 'pending'
  )
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.redeem_reward(text, text, integer) to authenticated;

-- Rotate Eco-ID QR token for current user
create or replace function public.rotate_qr_token()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_token text;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  v_token := encode(gen_random_bytes(24), 'hex');

  update public.profiles
  set
    qr_token = v_token,
    qr_token_rotated_at = now()
  where id = v_uid;

  return v_token;
end;
$$;

grant execute on function public.rotate_qr_token() to authenticated;

-- Allow students to update only their own qr_token via RPC above;
-- keep direct update of green_points locked down by existing RLS.
