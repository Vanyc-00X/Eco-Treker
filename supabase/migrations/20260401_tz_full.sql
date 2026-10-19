-- =============================================================================
-- Campus Eco-Tracker — FULL RESET + SCHEMA
-- Внимание: удаляет все таблицы приложения и создаёт схему заново.
-- Auth-пользователи (auth.users) НЕ удаляются.
-- Запускать в Supabase SQL Editor целиком → Run without RLS
-- (RLS включается внутри скрипта вместе с политиками).
-- =============================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 0. DROP (порядок с учётом FK)
-- ---------------------------------------------------------------------------
drop view if exists public.leaderboard_students cascade;
drop view if exists public.leaderboard_groups cascade;
drop view if exists public.leaderboard_faculties cascade;

drop function if exists public.touch_last_active() cascade;
drop function if exists public.leaderboard_students(text, timestamptz, text, text, integer) cascade;
drop function if exists public.export_my_activity() cascade;
drop function if exists public.soft_delete_account() cascade;
drop function if exists public.abandon_challenge(uuid) cascade;
drop function if exists public.moderate_submission(uuid, boolean, text) cascade;
drop function if exists public.confirm_dropoff(uuid, uuid, numeric, uuid, numeric) cascade;
drop function if exists public.award_achievement_by_code(uuid, text) cascade;
drop function if exists public.lookup_by_qr_token(text) cascade;
drop function if exists public.current_role() cascade;
drop function if exists public.rotate_qr_token() cascade;
drop function if exists public.redeem_reward(text, text, integer) cascade;
drop function if exists public.handle_new_user() cascade;

drop table if exists public.favorites_points cascade;
drop table if exists public.otp_attempts cascade;
drop table if exists public.point_disputes cascade;
drop table if exists public.challenge_proofs cascade;
drop table if exists public.user_achievements cascade;
drop table if exists public.challenge_participations cascade;
drop table if exists public.bin_reports cascade;
drop table if exists public.redeem_requests cascade;
drop table if exists public.recycling_submissions cascade;
drop table if exists public.waste_subcategories cascade;
drop table if exists public.waste_categories cascade;
drop table if exists public.collection_points cascade;
drop table if exists public.challenges cascade;
drop table if exists public.achievements cascade;
drop table if exists public.groups cascade;
drop table if exists public.faculties cascade;
drop table if exists public.profiles cascade;

drop type if exists public.waste_fraction cascade;
drop type if exists public.user_role cascade;
drop type if exists public.eco_level cascade;
drop type if exists public.submission_method cascade;
drop type if exists public.submission_status cascade;

-- ---------------------------------------------------------------------------
-- 1. Faculties / groups
-- ---------------------------------------------------------------------------
create table public.faculties (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  short_name text
);

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  faculty_id uuid references public.faculties (id) on delete set null
);

-- ---------------------------------------------------------------------------
-- 2. Profiles (1:1 with auth.users)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null default '',
  full_name text not null default 'Student',
  role text not null default 'student'
    check (role in ('student', 'volunteer', 'admin')),
  eco_level text not null default 'eco_novice'
    check (eco_level in ('eco_novice', 'forest_keeper', 'eco_master')),
  green_points integer not null default 0,
  total_kg numeric not null default 0,
  co2_saved_kg numeric not null default 0,
  avatar_url text,
  qr_token text,
  qr_token_rotated_at timestamptz,
  faculty_id uuid references public.faculties (id) on delete set null,
  group_id uuid references public.groups (id) on delete set null,
  faculty_name text,
  group_name text,
  course integer,
  phone text,
  date_of_birth date,
  privacy_consent_at timestamptz,
  tos_accepted_at timestamptz,
  verified boolean not null default false,
  last_active_at timestamptz,
  profile_visibility text not null default 'public'
    check (profile_visibility in ('public', 'friends', 'private')),
  show_in_leaderboard boolean not null default true,
  notification_prefs jsonb not null default '{
    "challenges": true,
    "reminders": true,
    "ranking": true,
    "system": true,
    "promos": false
  }'::jsonb,
  accent_color text default 'green',
  mfa_enabled boolean not null default false,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index profiles_qr_token_uidx
  on public.profiles (qr_token)
  where qr_token is not null;

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, qr_token, qr_token_rotated_at)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data->>'full_name', 'Student'),
    encode(gen_random_bytes(24), 'hex'),
    now()
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(nullif(excluded.full_name, ''), public.profiles.full_name);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- 3. Waste categories
-- ---------------------------------------------------------------------------
create table public.waste_categories (
  id uuid primary key default gen_random_uuid(),
  fraction text not null unique
    check (fraction in ('paper', 'plastic', 'glass', 'metal', 'hazardous')),
  name_ru text not null,
  points_per_kg integer not null default 0,
  co2_per_kg numeric not null default 0
);

insert into public.waste_categories (fraction, name_ru, points_per_kg, co2_per_kg) values
  ('paper', 'Макулатура', 30, 0.9),
  ('plastic', 'Пластик', 50, 1.5),
  ('glass', 'Стекло', 20, 0.6),
  ('metal', 'Металл / Алюминий', 70, 2.1),
  ('hazardous', 'Опасные отходы (батарейки)', 10, 0.3);

create table public.waste_subcategories (
  id uuid primary key default gen_random_uuid(),
  category_id uuid not null references public.waste_categories (id) on delete cascade,
  code text not null,
  name_ru text not null,
  unique (category_id, code)
);

insert into public.waste_subcategories (category_id, code, name_ru)
select c.id, s.code, s.name_ru
from public.waste_categories c
join (values
  ('paper', 'office', 'Офисная бумага / газеты'),
  ('paper', 'cardboard', 'Картон'),
  ('paper', 'books', 'Книги'),
  ('plastic', 'pet', 'PET бутылки'),
  ('plastic', 'hdpe', 'HDPE флаконы'),
  ('plastic', 'ldpe', 'LDPE пакеты'),
  ('plastic', 'pp', 'PP контейнеры'),
  ('plastic', 'ps', 'PS стаканчики'),
  ('plastic', 'other', 'Другой пластик'),
  ('glass', 'bottles', 'Бутылки'),
  ('glass', 'jars', 'Банки'),
  ('glass', 'cullet', 'Бой стекла'),
  ('metal', 'alu_cans', 'Алюминиевые банки'),
  ('metal', 'tin', 'Жестяные банки'),
  ('metal', 'scrap', 'Металлолом'),
  ('hazardous', 'aa', 'Пальчиковые / мизинчиковые'),
  ('hazardous', 'button', 'Кроны'),
  ('hazardous', 'accum', 'Аккумуляторы'),
  ('hazardous', 'lamps', 'Ртутные лампы')
) as s(fraction, code, name_ru) on c.fraction = s.fraction;

-- ---------------------------------------------------------------------------
-- 4. Collection points
-- ---------------------------------------------------------------------------
create table public.collection_points (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  latitude double precision not null,
  longitude double precision not null,
  address text not null default '',
  work_hours text not null default '09:00–18:00',
  open_hours text,
  accepted_fractions text[] not null default array['plastic','paper','glass','metal','hazardous'],
  is_active boolean not null default true,
  description text,
  fill_percent integer not null default 0 check (fill_percent >= 0 and fill_percent <= 100),
  photo_url text,
  contact_phone text,
  contact_name text,
  is_accessible boolean not null default false
);

insert into public.collection_points
  (name, latitude, longitude, address, work_hours, accepted_fractions, fill_percent, is_accessible)
values
  ('Корпус А — холл', 55.7558, 37.6173, 'Кампус, корпус А', '08:00–20:00',
   array['plastic','paper'], 35, true),
  ('Общежитие №2', 55.7565, 37.6185, 'Кампус, общежитие 2', '09:00–21:00',
   array['plastic','glass','metal'], 55, false),
  ('Эко-пункт у столовой', 55.7549, 37.6160, 'Кампус, столовая', '10:00–18:00',
   array['paper','plastic','glass','metal','hazardous'], 20, true);

-- ---------------------------------------------------------------------------
-- 5. Recycling submissions
-- ---------------------------------------------------------------------------
create table public.recycling_submissions (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  category_id uuid not null references public.waste_categories (id),
  collection_point_id uuid references public.collection_points (id) on delete set null,
  subcategory_id uuid references public.waste_subcategories (id) on delete set null,
  method text not null default 'photo_claim'
    check (method in ('photo_claim', 'qr_scan', 'iot')),
  status text not null default 'pending'
    check (status in ('pending', 'verified', 'rejected')),
  weight_kg numeric not null check (weight_kg > 0),
  points_awarded integer default 0,
  co2_awarded numeric default 0,
  bonus_multiplier numeric not null default 1,
  photo_url text,
  note text,
  reviewer_note text,
  latitude double precision,
  longitude double precision,
  submitted_at timestamptz not null default now(),
  verified_at timestamptz
);

create index recycling_submissions_student_idx
  on public.recycling_submissions (student_id, submitted_at desc);

-- ---------------------------------------------------------------------------
-- 6. Challenges + achievements
-- ---------------------------------------------------------------------------
create table public.challenges (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  challenge_type text not null default 'individual'
    check (challenge_type in ('individual','team','daily','weekly','seasonal','special')),
  reward_points integer not null default 50,
  target_fraction text,
  target_kg numeric,
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null default (now() + interval '14 days'),
  is_published boolean not null default true
);

insert into public.challenges (title, description, challenge_type, reward_points, target_kg, target_fraction)
values
  ('Сдай 3 кг макулатуры', 'Индивидуальный челлендж недели', 'individual', 80, 3, 'paper'),
  ('Неделя пластика', 'Сдайте 5 кг пластика за неделю', 'weekly', 120, 5, 'plastic'),
  ('Команда факультета', 'Соберите 50 кг вместе', 'team', 200, 50, 'plastic'),
  ('Весенний марафон', 'Сезонный эко-забег', 'seasonal', 150, 10, null),
  ('День Земли', 'Специальное событие: 5 кг любого сырья', 'special', 100, 5, null);

create table public.challenge_participations (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'active'
    check (status in ('active', 'completed', 'abandoned')),
  progress_kg numeric not null default 0,
  proof_photo_url text,
  joined_at timestamptz not null default now(),
  completed_at timestamptz,
  abandoned_at timestamptz,
  unique (challenge_id, user_id)
);

create table public.achievements (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  title text not null,
  description text,
  icon_url text,
  title_ru text,
  description_ru text,
  icon text
);

insert into public.achievements (code, title, description, icon_url, title_ru, description_ru, icon)
values
  ('first_step', 'Первый шаг', 'Первая сдача сырья', 'footprint', 'Первый шаг', 'Первая сдача сырья', 'footprint'),
  ('eco_novice', 'Эко-новичок', '10 кг сданного сырья', 'seedling', 'Эко-новичок', '10 кг сданного сырья', 'seedling'),
  ('forest_keeper', 'Хранитель леса', '50 кг сданного сырья', 'tree', 'Хранитель леса', '50 кг сданного сырья', 'tree'),
  ('eco_master', 'Эко-магистр', '100 кг сданного сырья', 'crown', 'Эко-магистр', '100 кг сданного сырья', 'crown'),
  ('battery_king', 'Батарейный король', '100 батареек', 'battery', 'Батарейный король', '100 батареек', 'battery'),
  ('plastic_warrior', 'Пластиковый воин', '50 кг пластика', 'recycle', 'Пластиковый воин', '50 кг пластика', 'recycle'),
  ('paper_hero', 'Бумажный герой', '50 кг макулатуры', 'description', 'Бумажный герой', '50 кг макулатуры', 'description'),
  ('glass_guard', 'Стеклянный страж', '50 кг стекла', 'local_bar', 'Стеклянный страж', '50 кг стекла', 'local_bar'),
  ('metal_lord', 'Металлический лорд', '50 кг металла', 'hardware', 'Металлический лорд', '50 кг металла', 'hardware'),
  ('challenge_master', 'Челлендж-мастер', '10 выполненных челленджей', 'emoji_events', 'Челлендж-мастер', '10 выполненных челленджей', 'emoji_events'),
  ('team_player', 'Командный игрок', '5 командных челленджей', 'groups', 'Командный игрок', '5 командных челленджей', 'groups'),
  ('daily_activist', 'Ежедневный эко-активист', '30 дней подряд', 'calendar', 'Ежедневный эко-активист', '30 дней подряд', 'calendar');

create table public.user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  achievement_id uuid not null references public.achievements (id) on delete cascade,
  earned_at timestamptz not null default now(),
  unique (user_id, achievement_id)
);

create table public.challenge_proofs (
  id uuid primary key default gen_random_uuid(),
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  photo_url text not null,
  comment text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  reviewer_note text,
  created_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 7. Redeem / bin reports / disputes / favorites / otp
-- ---------------------------------------------------------------------------
create table public.redeem_requests (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  reward_code text not null,
  reward_title text not null,
  points_cost integer not null check (points_cost > 0),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'fulfilled')),
  created_at timestamptz not null default now()
);

create index redeem_requests_student_idx
  on public.redeem_requests (student_id, created_at desc);

create table public.bin_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  collection_point_id uuid not null references public.collection_points (id) on delete cascade,
  note text,
  status text not null default 'open'
    check (status in ('open', 'acknowledged', 'resolved')),
  created_at timestamptz not null default now()
);

create index bin_reports_point_idx
  on public.bin_reports (collection_point_id, created_at desc);

create table public.point_disputes (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.profiles (id) on delete cascade,
  submission_id uuid references public.recycling_submissions (id) on delete set null,
  reason text not null,
  status text not null default 'open'
    check (status in ('open', 'resolved', 'rejected')),
  created_at timestamptz not null default now()
);

create table public.favorites_points (
  user_id uuid not null references public.profiles (id) on delete cascade,
  collection_point_id uuid not null references public.collection_points (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, collection_point_id)
);

create table public.otp_attempts (
  id uuid primary key default gen_random_uuid(),
  phone text not null unique,
  attempts integer not null default 0,
  locked_until timestamptz,
  updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- 8. Leaderboard views
-- ---------------------------------------------------------------------------
create or replace view public.leaderboard_students as
select
  p.id,
  p.full_name,
  p.green_points,
  p.total_kg,
  p.group_name,
  p.faculty_name as faculty_short,
  rank() over (order by p.green_points desc) as rank
from public.profiles p
where p.deleted_at is null
  and p.show_in_leaderboard = true
  and p.role = 'student';

create or replace view public.leaderboard_groups as
select
  (
    substr(md5(p.group_name), 1, 8) || '-' ||
    substr(md5(p.group_name), 9, 4) || '-' ||
    substr(md5(p.group_name), 13, 4) || '-' ||
    substr(md5(p.group_name), 17, 4) || '-' ||
    substr(md5(p.group_name), 21, 12)
  )::uuid as id,
  coalesce(p.group_name, 'Без группы') as name,
  sum(p.green_points)::integer as green_points,
  sum(p.total_kg) as total_kg,
  max(p.faculty_name) as faculty_short,
  rank() over (order by sum(p.green_points) desc) as rank
from public.profiles p
where p.deleted_at is null and p.role = 'student' and p.group_name is not null
group by p.group_name;

create or replace view public.leaderboard_faculties as
select
  (
    substr(md5(p.faculty_name), 1, 8) || '-' ||
    substr(md5(p.faculty_name), 9, 4) || '-' ||
    substr(md5(p.faculty_name), 13, 4) || '-' ||
    substr(md5(p.faculty_name), 17, 4) || '-' ||
    substr(md5(p.faculty_name), 21, 12)
  )::uuid as id,
  coalesce(p.faculty_name, 'Без факультета') as name,
  max(p.faculty_name) as short_name,
  sum(p.green_points)::integer as green_points,
  sum(p.total_kg) as total_kg,
  rank() over (order by sum(p.green_points) desc) as rank
from public.profiles p
where p.deleted_at is null and p.role = 'student' and p.faculty_name is not null
group by p.faculty_name;

-- ---------------------------------------------------------------------------
-- 9. RPC helpers
-- ---------------------------------------------------------------------------
create or replace function public.current_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role from public.profiles where id = auth.uid()),
    'anon'
  );
$$;

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
  if v_uid is null then raise exception 'Not authenticated'; end if;
  v_token := encode(gen_random_bytes(24), 'hex');
  update public.profiles
  set qr_token = v_token, qr_token_rotated_at = now()
  where id = v_uid;
  return v_token;
end;
$$;

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
  if v_uid is null then raise exception 'Not authenticated'; end if;
  if p_points_cost is null or p_points_cost <= 0 then
    raise exception 'Invalid points cost';
  end if;
  select green_points into v_points from public.profiles where id = v_uid for update;
  if v_points is null then raise exception 'Profile not found'; end if;
  if v_points < p_points_cost then raise exception 'Недостаточно баллов'; end if;
  update public.profiles set green_points = green_points - p_points_cost where id = v_uid;
  insert into public.redeem_requests (student_id, reward_code, reward_title, points_cost, status)
  values (v_uid, p_reward_code, p_reward_title, p_points_cost, 'pending')
  returning * into v_row;
  return v_row;
end;
$$;

create or replace function public.award_achievement_by_code(p_user_id uuid, p_code text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_aid uuid;
begin
  select id into v_aid from public.achievements where code = p_code;
  if v_aid is null then return; end if;
  insert into public.user_achievements (user_id, achievement_id)
  values (p_user_id, v_aid)
  on conflict (user_id, achievement_id) do nothing;
end;
$$;

create or replace function public.lookup_by_qr_token(p_token text)
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare v_row public.profiles;
begin
  if public.current_role() not in ('volunteer', 'admin') then
    raise exception 'Forbidden';
  end if;
  select * into v_row from public.profiles
  where qr_token = p_token and deleted_at is null;
  if not found then raise exception 'QR token not found or expired'; end if;
  return v_row;
end;
$$;

create or replace function public.confirm_dropoff(
  p_student_id uuid,
  p_category_id uuid,
  p_weight_kg numeric,
  p_collection_point_id uuid default null,
  p_bonus_multiplier numeric default 1
)
returns public.recycling_submissions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_cat public.waste_categories;
  v_points integer;
  v_co2 numeric;
  v_mult numeric := greatest(coalesce(p_bonus_multiplier, 1), 0.1);
  v_row public.recycling_submissions;
  v_total numeric;
begin
  if public.current_role() not in ('volunteer', 'admin') then
    raise exception 'Forbidden';
  end if;
  if p_weight_kg is null or p_weight_kg <= 0 or p_weight_kg > 200 then
    raise exception 'Invalid weight';
  end if;
  select * into v_cat from public.waste_categories where id = p_category_id;
  if not found then raise exception 'Category not found'; end if;

  v_points := round(p_weight_kg * v_cat.points_per_kg * v_mult)::integer;
  v_co2 := round((p_weight_kg * v_cat.co2_per_kg * v_mult)::numeric, 3);

  insert into public.recycling_submissions (
    student_id, category_id, collection_point_id, method, status,
    weight_kg, points_awarded, co2_awarded, bonus_multiplier, verified_at
  ) values (
    p_student_id, p_category_id, p_collection_point_id, 'qr_scan', 'verified',
    p_weight_kg, v_points, v_co2, v_mult, now()
  ) returning * into v_row;

  update public.profiles set
    green_points = green_points + v_points,
    total_kg = total_kg + p_weight_kg,
    co2_saved_kg = co2_saved_kg + v_co2,
    last_active_at = now()
  where id = p_student_id;

  select total_kg into v_total from public.profiles where id = p_student_id;
  if v_total >= 100 then
    update public.profiles set eco_level = 'eco_master' where id = p_student_id;
  elsif v_total >= 50 then
    update public.profiles set eco_level = 'forest_keeper' where id = p_student_id;
  end if;

  perform public.award_achievement_by_code(p_student_id, 'first_step');
  if v_total >= 10 then perform public.award_achievement_by_code(p_student_id, 'eco_novice'); end if;
  if v_total >= 50 then perform public.award_achievement_by_code(p_student_id, 'forest_keeper'); end if;
  if v_total >= 100 then perform public.award_achievement_by_code(p_student_id, 'eco_master'); end if;

  return v_row;
end;
$$;

create or replace function public.moderate_submission(
  p_submission_id uuid,
  p_approve boolean,
  p_reviewer_note text default null
)
returns public.recycling_submissions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row public.recycling_submissions;
  v_cat public.waste_categories;
  v_points integer;
  v_co2 numeric;
  v_mult numeric;
begin
  if public.current_role() not in ('volunteer', 'admin') then
    raise exception 'Forbidden';
  end if;
  select * into v_row from public.recycling_submissions where id = p_submission_id for update;
  if not found then raise exception 'Submission not found'; end if;
  if v_row.status <> 'pending' then raise exception 'Already moderated'; end if;

  if not p_approve then
    update public.recycling_submissions
    set status = 'rejected', reviewer_note = p_reviewer_note
    where id = p_submission_id
    returning * into v_row;
    return v_row;
  end if;

  select * into v_cat from public.waste_categories where id = v_row.category_id;
  v_mult := coalesce(v_row.bonus_multiplier, 1);
  v_points := round(v_row.weight_kg * v_cat.points_per_kg * v_mult)::integer;
  v_co2 := round((v_row.weight_kg * v_cat.co2_per_kg * v_mult)::numeric, 3);

  update public.recycling_submissions set
    status = 'verified',
    points_awarded = v_points,
    co2_awarded = v_co2,
    reviewer_note = p_reviewer_note,
    verified_at = now()
  where id = p_submission_id
  returning * into v_row;

  update public.profiles set
    green_points = green_points + v_points,
    total_kg = total_kg + v_row.weight_kg,
    co2_saved_kg = co2_saved_kg + v_co2,
    last_active_at = now()
  where id = v_row.student_id;

  perform public.award_achievement_by_code(v_row.student_id, 'first_step');
  return v_row;
end;
$$;

create or replace function public.abandon_challenge(p_challenge_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.challenge_participations set
    status = 'abandoned', abandoned_at = now()
  where challenge_id = p_challenge_id and user_id = auth.uid();
end;
$$;

create or replace function public.soft_delete_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'Not authenticated'; end if;
  update public.profiles set
    full_name = 'Удалённый пользователь',
    email = 'deleted_' || v_uid::text || '@deleted.local',
    phone = null,
    avatar_url = null,
    qr_token = null,
    show_in_leaderboard = false,
    profile_visibility = 'private',
    deleted_at = now()
  where id = v_uid;
end;
$$;

create or replace function public.export_my_activity()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  return coalesce((
    select jsonb_agg(to_jsonb(s) order by s.submitted_at desc)
    from public.recycling_submissions s
    where s.student_id = auth.uid()
  ), '[]'::jsonb);
end;
$$;

create or replace function public.leaderboard_students(
  p_metric text default 'points',
  p_from timestamptz default null,
  p_faculty text default null,
  p_group text default null,
  p_course integer default null
)
returns table (
  id uuid,
  title text,
  subtitle text,
  score numeric,
  rank bigint
)
language sql
stable
security definer
set search_path = public
as $$
  with base as (
    select
      p.id,
      p.full_name as title,
      coalesce(p.group_name, p.faculty_name, '') as subtitle,
      case
        when p_metric = 'kg' then coalesce(sum(s.weight_kg) filter (where s.status = 'verified'), 0)
        when p_metric = 'co2' then coalesce(sum(s.co2_awarded) filter (where s.status = 'verified'), p.co2_saved_kg)
        when p_metric = 'challenges' then (
          select count(*)::numeric from public.challenge_participations cp
          where cp.user_id = p.id and cp.status = 'completed'
        )
        else coalesce(p.green_points, 0)::numeric
      end as score
    from public.profiles p
    left join public.recycling_submissions s
      on s.student_id = p.id
      and (p_from is null or s.submitted_at >= p_from)
    where p.deleted_at is null
      and p.show_in_leaderboard = true
      and p.role = 'student'
      and (p_faculty is null or p.faculty_name = p_faculty)
      and (p_group is null or p.group_name = p_group)
      and (p_course is null or p.course = p_course)
    group by p.id
  )
  select b.id, b.title, b.subtitle, b.score,
         rank() over (order by b.score desc) as rank
  from base b
  order by rank
  limit 100;
$$;

create or replace function public.touch_last_active()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set last_active_at = now() where id = auth.uid();
end;
$$;

grant execute on function public.current_role() to authenticated;
grant execute on function public.rotate_qr_token() to authenticated;
grant execute on function public.redeem_reward(text, text, integer) to authenticated;
grant execute on function public.award_achievement_by_code(uuid, text) to authenticated;
grant execute on function public.lookup_by_qr_token(text) to authenticated;
grant execute on function public.confirm_dropoff(uuid, uuid, numeric, uuid, numeric) to authenticated;
grant execute on function public.moderate_submission(uuid, boolean, text) to authenticated;
grant execute on function public.abandon_challenge(uuid) to authenticated;
grant execute on function public.soft_delete_account() to authenticated;
grant execute on function public.export_my_activity() to authenticated;
grant execute on function public.leaderboard_students(text, timestamptz, text, text, integer) to authenticated;
grant execute on function public.touch_last_active() to authenticated;

-- ---------------------------------------------------------------------------
-- 10. RLS
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.waste_categories enable row level security;
alter table public.waste_subcategories enable row level security;
alter table public.collection_points enable row level security;
alter table public.recycling_submissions enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_participations enable row level security;
alter table public.achievements enable row level security;
alter table public.user_achievements enable row level security;
alter table public.challenge_proofs enable row level security;
alter table public.redeem_requests enable row level security;
alter table public.bin_reports enable row level security;
alter table public.point_disputes enable row level security;
alter table public.favorites_points enable row level security;
alter table public.faculties enable row level security;
alter table public.groups enable row level security;

-- Profiles
create policy "profiles_select" on public.profiles for select to authenticated
  using (
    id = auth.uid()
    or public.current_role() in ('volunteer', 'admin')
    or (show_in_leaderboard and deleted_at is null and profile_visibility = 'public')
  );
create policy "profiles_update_own" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_insert_own" on public.profiles for insert to authenticated
  with check (id = auth.uid());

-- Catalogs (read)
create policy "waste_categories_read" on public.waste_categories for select to authenticated using (true);
create policy "waste_subcategories_read" on public.waste_subcategories for select to authenticated using (true);
create policy "collection_points_read" on public.collection_points for select to authenticated using (true);
create policy "collection_points_admin" on public.collection_points for all to authenticated
  using (public.current_role() = 'admin') with check (public.current_role() = 'admin');
create policy "faculties_read" on public.faculties for select to authenticated using (true);
create policy "groups_read" on public.groups for select to authenticated using (true);
create policy "achievements_read" on public.achievements for select to authenticated using (true);
create policy "challenges_read" on public.challenges for select to authenticated using (is_published or public.current_role() = 'admin');
create policy "challenges_admin" on public.challenges for all to authenticated
  using (public.current_role() = 'admin') with check (public.current_role() = 'admin');

-- Submissions
create policy "submissions_select" on public.recycling_submissions for select to authenticated
  using (student_id = auth.uid() or public.current_role() in ('volunteer', 'admin'));
create policy "submissions_insert_own" on public.recycling_submissions for insert to authenticated
  with check (student_id = auth.uid());
create policy "submissions_staff_update" on public.recycling_submissions for update to authenticated
  using (public.current_role() in ('volunteer', 'admin'));

-- Challenges participation
create policy "participation_select" on public.challenge_participations for select to authenticated
  using (user_id = auth.uid() or public.current_role() in ('volunteer', 'admin'));
create policy "participation_upsert" on public.challenge_participations for insert to authenticated
  with check (user_id = auth.uid());
create policy "participation_update" on public.challenge_participations for update to authenticated
  using (user_id = auth.uid());

create policy "user_achievements_select" on public.user_achievements for select to authenticated
  using (user_id = auth.uid() or public.current_role() in ('volunteer', 'admin'));

create policy "proofs_insert" on public.challenge_proofs for insert to authenticated
  with check (user_id = auth.uid());
create policy "proofs_select" on public.challenge_proofs for select to authenticated
  using (user_id = auth.uid() or public.current_role() in ('volunteer', 'admin'));
create policy "proofs_staff_update" on public.challenge_proofs for update to authenticated
  using (public.current_role() in ('volunteer', 'admin'));

-- Redeem / bins / disputes / favorites
create policy "redeem_insert" on public.redeem_requests for insert to authenticated
  with check (student_id = auth.uid());
create policy "redeem_select" on public.redeem_requests for select to authenticated
  using (student_id = auth.uid() or public.current_role() in ('volunteer', 'admin'));
create policy "redeem_staff_update" on public.redeem_requests for update to authenticated
  using (public.current_role() in ('volunteer', 'admin'));

create policy "bin_insert" on public.bin_reports for insert to authenticated
  with check (reporter_id = auth.uid());
create policy "bin_select" on public.bin_reports for select to authenticated
  using (reporter_id = auth.uid() or public.current_role() in ('volunteer', 'admin'));
create policy "bin_staff_update" on public.bin_reports for update to authenticated
  using (public.current_role() in ('volunteer', 'admin'));

create policy "disputes_insert" on public.point_disputes for insert to authenticated
  with check (student_id = auth.uid());
create policy "disputes_select" on public.point_disputes for select to authenticated
  using (student_id = auth.uid() or public.current_role() in ('volunteer', 'admin'));

create policy "favorites_all" on public.favorites_points for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 11. Storage buckets (submissions + avatars)
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('submissions', 'submissions', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

drop policy if exists "submissions_upload" on storage.objects;
create policy "submissions_upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'submissions');

drop policy if exists "submissions_read" on storage.objects;
create policy "submissions_read" on storage.objects for select to authenticated
  using (bucket_id = 'submissions');

drop policy if exists "submissions_update" on storage.objects;
create policy "submissions_update" on storage.objects for update to authenticated
  using (bucket_id = 'submissions');

drop policy if exists "avatars_upload" on storage.objects;
create policy "avatars_upload" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars');

drop policy if exists "avatars_read" on storage.objects;
create policy "avatars_read" on storage.objects for select to authenticated
  using (bucket_id = 'avatars');

drop policy if exists "avatars_update" on storage.objects;
create policy "avatars_update" on storage.objects for update to authenticated
  using (bucket_id = 'avatars');

-- ---------------------------------------------------------------------------
-- 12. Backfill profiles for already registered auth users
-- ---------------------------------------------------------------------------
insert into public.profiles (id, email, full_name, qr_token, qr_token_rotated_at)
select
  u.id,
  coalesce(u.email, ''),
  coalesce(u.raw_user_meta_data->>'full_name', 'Student'),
  encode(gen_random_bytes(24), 'hex'),
  now()
from auth.users u
on conflict (id) do nothing;

-- Done.
select 'Campus Eco-Tracker schema ready' as status;
