-- =============================================================================
-- Demo seed: ~30 правдоподобных строк в каждую таблицу приложения (МЦК-КТИТС).
--
-- Запускать ПОСЛЕ 20260401 + 20260403 + 20260404 в SQL Editor.
-- Идемпотентно по маркеру email / seed-кодам (можно перезапускать).
--
-- Демо-вход (все студенты):  seed01@mck-ktits.demo … seed30@mck-ktits.demo
-- Пароль:                   DemoPass1!
--
-- Исключение: waste_categories — в схеме только 5 фракций (CHECK),
-- уже заполнены базовой миграцией; сюда не дублируем.
-- =============================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- 0. Временные справочники имён / групп
-- ---------------------------------------------------------------------------
drop table if exists public._seed_people;
create table public._seed_people (
  n int primary key,
  full_name text not null,
  role text not null,
  course int not null,
  group_name text not null,
  faculty_name text not null,
  phone text not null,
  points int not null,
  kg numeric not null,
  co2 numeric not null,
  eco_level text not null
);

insert into public._seed_people values
  (1,  'Айрат Закиров',           'student',   2, 'ИСп-221', 'Информационные технологии',              '+79061234001', 420, 18.4, 27.6, 'forest_keeper'),
  (2,  'Камила Нуриева',          'student',   1, 'ИСп-241', 'Базовая профессиональная подготовка',     '+79061234002', 95,  3.2,  4.8,  'eco_novice'),
  (3,  'Данил Смирнов',           'student',   3, 'ССАп-211', 'Сетевые технологии',                     '+79061234003', 610, 31.0, 46.5, 'forest_keeper'),
  (4,  'Эльвина Гарипова',        'student',   2, 'ВРп-221', 'Информационные технологии',              '+79061234004', 280, 12.1, 18.2, 'eco_novice'),
  (5,  'Тимур Хасанов',           'volunteer', 3, 'ИБп-211', 'Информационная безопасность и связь',    '+79061234005', 150, 6.5,  9.8,  'eco_novice'),
  (6,  'Анна Петрова',            'student',   4, 'ИСп-201', 'Информационные технологии',              '+79061234006', 980, 52.3, 78.4, 'eco_master'),
  (7,  'Рустам Валиев',           'student',   1, 'ССАп-241', 'Базовая профессиональная подготовка',   '+79061234007', 40,  1.1,  1.6,  'eco_novice'),
  (8,  'Мария Соколова',          'student',   2, 'ИИп-221', 'Информационные технологии',              '+79061234008', 355, 15.8, 23.7, 'forest_keeper'),
  (9,  'Ильдар Сафиуллин',        'student',   3, 'КСКп-211', 'Сетевые технологии',                    '+79061234009', 505, 24.0, 36.0, 'forest_keeper'),
  (10, 'Алина Фаттахова',         'admin',     4, 'Админ',   'Администрация техникума',                '+79061234010', 0,   0,    0,    'eco_novice'),
  (11, 'Кирилл Орлов',            'student',   2, 'ПСп-221', 'Информационная безопасность и связь',    '+79061234011', 190, 8.4,  12.6, 'eco_novice'),
  (12, 'Гузель Мингалиева',       'student',   1, 'ВРп-241', 'Базовая профессиональная подготовка',    '+79061234012', 70,  2.5,  3.8,  'eco_novice'),
  (13, 'Павел Кузнецов',          'student',   3, 'ИСп-211', 'Информационные технологии',              '+79061234013', 730, 38.2, 57.3, 'forest_keeper'),
  (14, 'Лейсан Абдуллина',        'volunteer', 2, 'ССАп-221', 'Сетевые технологии',                    '+79061234014', 220, 9.9,  14.8, 'eco_novice'),
  (15, 'Никита Белов',            'student',   4, 'ИБп-201', 'Информационная безопасность и связь',    '+79061234015', 860, 44.1, 66.2, 'eco_master'),
  (16, 'Диана Юсупова',           'student',   2, 'ИСп-222', 'Информационные технологии',              '+79061234016', 310, 13.6, 20.4, 'eco_novice'),
  (17, 'Артём Иванов',            'student',   1, 'КСКп-241', 'Базовая профессиональная подготовка',   '+79061234017', 55,  1.8,  2.7,  'eco_novice'),
  (18, 'Регина Шакирова',         'student',   3, 'ВРп-211', 'Информационные технологии',              '+79061234018', 470, 21.5, 32.2, 'forest_keeper'),
  (19, 'Егор Морозов',            'student',   2, 'ИИп-222', 'Информационные технологии',              '+79061234019', 265, 11.2, 16.8, 'eco_novice'),
  (20, 'Алия Каримова',           'student',   4, 'ССАп-201', 'Сетевые технологии',                    '+79061234020', 910, 48.0, 72.0, 'eco_master'),
  (21, 'Максим Воробьёв',         'student',   1, 'ИСп-242', 'Базовая профессиональная подготовка',    '+79061234021', 120, 4.0,  6.0,  'eco_novice'),
  (22, 'Сабина Халилова',         'student',   3, 'ПСп-211', 'Информационная безопасность и связь',    '+79061234022', 540, 26.7, 40.0, 'forest_keeper'),
  (23, 'Владислав Ермолаев',      'student',   2, 'ИБп-221', 'Информационная безопасность и связь',    '+79061234023', 205, 9.1,  13.6, 'eco_novice'),
  (24, 'Полина Чернова',          'volunteer', 3, 'ИСп-212', 'Информационные технологии',              '+79061234024', 175, 7.3,  11.0, 'eco_novice'),
  (25, 'Булат Гайнуллин',         'student',   4, 'КСКп-201', 'Сетевые технологии',                    '+79061234025', 790, 41.0, 61.5, 'eco_master'),
  (26, 'Екатерина Лебедева',      'student',   1, 'ВРп-242', 'Базовая профессиональная подготовка',    '+79061234026', 85,  2.9,  4.3,  'eco_novice'),
  (27, 'Адель Мухаметшин',        'student',   2, 'ССАп-222', 'Сетевые технологии',                    '+79061234027', 335, 14.5, 21.8, 'forest_keeper'),
  (28, 'София Григорьева',        'student',   3, 'ИИп-211', 'Информационные технологии',              '+79061234028', 455, 20.0, 30.0, 'forest_keeper'),
  (29, 'Ильназ Рахимов',          'student',   2, 'ПСп-222', 'Информационная безопасность и связь',    '+79061234029', 240, 10.4, 15.6, 'eco_novice'),
  (30, 'Вероника Фёдорова',       'student',   4, 'ИСп-202', 'Информационные технологии',              '+79061234030', 670, 34.8, 52.2, 'forest_keeper');

-- ---------------------------------------------------------------------------
-- 1. auth.users + identities + profiles (30)
-- ---------------------------------------------------------------------------
do $$
declare
  r record;
  uid uuid;
  mail text;
  inst uuid := '00000000-0000-0000-0000-000000000000';
begin
  -- instance_id из существующего пользователя, если есть
  select id into inst from auth.instances limit 1;
  if inst is null then
    inst := '00000000-0000-0000-0000-000000000000';
  end if;

  for r in select * from public._seed_people order by n loop
    mail := 'seed' || lpad(r.n::text, 2, '0') || '@mck-ktits.demo';

    select id into uid from auth.users where email = mail;
    if uid is null then
      uid := gen_random_uuid();
      insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, recovery_sent_at, last_sign_in_at,
        raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
        confirmation_token, email_change, email_change_token_new, recovery_token
      ) values (
        inst, uid, 'authenticated', 'authenticated', mail,
        crypt('DemoPass1!', gen_salt('bf')),
        now(), null, now(),
        '{"provider":"email","providers":["email"]}'::jsonb,
        jsonb_build_object('full_name', r.full_name),
        now() - ((30 - r.n) || ' days')::interval,
        now(),
        '', '', '', ''
      );

      insert into auth.identities (
        id, user_id, identity_data, provider, provider_id,
        last_sign_in_at, created_at, updated_at
      ) values (
        gen_random_uuid(), uid,
        jsonb_build_object('sub', uid::text, 'email', mail, 'email_verified', true),
        'email', uid::text,
        now(), now(), now()
      );
    end if;

    insert into public.profiles (
      id, email, full_name, role, eco_level, green_points, total_kg, co2_saved_kg,
      qr_token, qr_token_rotated_at, faculty_name, group_name, course, phone,
      verified, last_active_at, show_in_leaderboard, privacy_consent_at, tos_accepted_at
    ) values (
      uid, mail, r.full_name, r.role, r.eco_level, r.points, r.kg, r.co2,
      encode(gen_random_bytes(24), 'hex'), now(),
      r.faculty_name, r.group_name, r.course, r.phone,
      true, now() - (r.n || ' hours')::interval,
      r.role = 'student',
      now() - interval '60 days', now() - interval '60 days'
    )
    on conflict (id) do update set
      full_name = excluded.full_name,
      role = excluded.role,
      eco_level = excluded.eco_level,
      green_points = excluded.green_points,
      total_kg = excluded.total_kg,
      co2_saved_kg = excluded.co2_saved_kg,
      faculty_name = excluded.faculty_name,
      group_name = excluded.group_name,
      course = excluded.course,
      phone = excluded.phone,
      verified = excluded.verified,
      show_in_leaderboard = excluded.show_in_leaderboard;
  end loop;
end $$;

-- карта n → profile id
drop table if exists public._seed_uids;
create table public._seed_uids as
select
  sp.n,
  p.id,
  sp.full_name,
  sp.role,
  sp.group_name,
  sp.faculty_name
from public._seed_people sp
join public.profiles p
  on p.email = 'seed' || lpad(sp.n::text, 2, '0') || '@mck-ktits.demo';

