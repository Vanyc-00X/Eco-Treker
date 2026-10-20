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

-- ---------------------------------------------------------------------------
-- 2. faculties (30) — отделения и учебные направления техникума
-- ---------------------------------------------------------------------------
delete from public.faculties
where short_name like 'SEED%';

insert into public.faculties (id, name, short_name)
select
  ('a1000000-0000-4000-8000-' || lpad(g::text, 12, '0'))::uuid,
  v.name,
  'SEED' || lpad(g::text, 2, '0')
from (values
  (1,  'Базовая профессиональная подготовка'),
  (2,  'Информационные технологии'),
  (3,  'Сетевые технологии'),
  (4,  'Информационная безопасность и связь'),
  (5,  'Компьютерные системы и комплексы'),
  (6,  'Сетевое и системное администрирование'),
  (7,  'Информационные системы и программирование'),
  (8,  'Веб-разработка (клиент)'),
  (9,  'Веб-разработка (сервер)'),
  (10, 'Разработка и управление ПО (C#)'),
  (11, 'Разработка и управление ПО (1С)'),
  (12, 'Интеллектуальные интегрированные системы'),
  (13, 'Интеграция решений с применением ИИ'),
  (14, 'Обеспечение информационной безопасности АС'),
  (15, 'Инфокоммуникационные сети и системы связи'),
  (16, 'Почтовая связь'),
  (17, 'Кибербезопасность кампуса'),
  (18, 'Облачные технологии и DevOps'),
  (19, 'Мобильная разработка'),
  (20, 'Администрирование Linux/Windows'),
  (21, 'Тестирование ПО (QA)'),
  (22, 'Цифровой дизайн интерфейсов'),
  (23, 'Базы данных и аналитика'),
  (24, 'Интернет вещей (IoT)'),
  (25, 'Техническая поддержка пользователей'),
  (26, 'Сетевая инженерия'),
  (27, 'Защита персональных данных'),
  (28, 'Мультимедиа и веб-контент'),
  (29, 'Проектная деятельность IT'),
  (30, 'Эко-волонтёрский штаб')
) as v(g, name)
on conflict (id) do update set name = excluded.name, short_name = excluded.short_name;

-- привязка профилей к факультетам
update public.profiles p
set faculty_id = f.id
from public._seed_uids u
join public.faculties f on f.short_name = 'SEED' || lpad(
  case u.faculty_name
    when 'Базовая профессиональная подготовка' then 1
    when 'Информационные технологии' then 2
    when 'Сетевые технологии' then 3
    when 'Информационная безопасность и связь' then 4
    when 'Администрация техникума' then 30
    else 2
  end::text, 2, '0')
where p.id = u.id;

-- ---------------------------------------------------------------------------
-- 3. groups (30)
-- ---------------------------------------------------------------------------
delete from public.groups where name like 'SEED-%' or name in (
  select group_name from public._seed_people
);

insert into public.groups (id, name, faculty_id)
select
  ('b2000000-0000-4000-8000-' || lpad(g::text, 12, '0'))::uuid,
  v.name,
  ('a1000000-0000-4000-8000-' || lpad(v.fac::text, 12, '0'))::uuid
from (values
  (1,  'ИСп-241',  1),
  (2,  'ИСп-242',  1),
  (3,  'ССАп-241', 1),
  (4,  'ВРп-241',  1),
  (5,  'КСКп-241', 1),
  (6,  'ВРп-242',  1),
  (7,  'ИСп-221',  2),
  (8,  'ИСп-222',  2),
  (9,  'ВРп-221',  2),
  (10, 'ИИп-221',  2),
  (11, 'ИИп-222',  2),
  (12, 'ИСп-211',  2),
  (13, 'ИСп-212',  2),
  (14, 'ВРп-211',  2),
  (15, 'ИИп-211',  2),
  (16, 'ИСп-201',  2),
  (17, 'ИСп-202',  2),
  (18, 'ССАп-221', 3),
  (19, 'ССАп-222', 3),
  (20, 'КСКп-211', 3),
  (21, 'ССАп-211', 3),
  (22, 'КСКп-201', 3),
  (23, 'ССАп-201', 3),
  (24, 'ИБп-221',  4),
  (25, 'ИБп-211',  4),
  (26, 'ПСп-221',  4),
  (27, 'ПСп-222',  4),
  (28, 'ПСп-211',  4),
  (29, 'ИБп-201',  4),
  (30, 'Админ',    30)
) as v(g, name, fac)
on conflict (id) do update set name = excluded.name, faculty_id = excluded.faculty_id;

update public.profiles p
set group_id = g.id
from public._seed_uids u
join public.groups g on g.name = u.group_name
where p.id = u.id;

-- ---------------------------------------------------------------------------
-- 4. waste_subcategories → довести до ≥30 (добавляем недостающие)
-- ---------------------------------------------------------------------------
insert into public.waste_subcategories (category_id, code, name_ru)
select c.id, s.code, s.name_ru
from public.waste_categories c
join (values
  ('paper', 'magazines', 'Журналы и каталоги'),
  ('paper', 'tetra', 'Тетрапак / комбинированная упаковка'),
  ('paper', 'notebooks', 'Тетради и блокноты'),
  ('plastic', 'film', 'Стрейч-плёнка'),
  ('plastic', 'caps', 'Крышки PET/HDPE'),
  ('plastic', 'blister', 'Блистерная упаковка'),
  ('glass', 'lab', 'Лабораторная посуда (без боя)'),
  ('glass', 'perfume', 'Флаконы от косметики'),
  ('metal', 'foil', 'Алюминиевая фольга'),
  ('metal', 'caps_metal', 'Металлические крышки'),
  ('hazardous', 'powerbank', 'Power bank / аккумуляторы устройств'),
  ('hazardous', 'thermometers', 'Ртутные термометры')
) as s(fraction, code, name_ru) on c.fraction = s.fraction
on conflict (category_id, code) do nothing;

-- ---------------------------------------------------------------------------
-- 5. collection_points (30) — Казань, ул. Бари Галеева / кампус
-- ---------------------------------------------------------------------------
delete from public.collection_points where contact_name = 'SEED_POINT';

insert into public.collection_points (
  id, name, latitude, longitude, address, work_hours, open_hours,
  accepted_fractions, is_active, description, fill_percent,
  contact_phone, contact_name, is_accessible
)
select
  ('c3000000-0000-4000-8000-' || lpad(v.n::text, 12, '0'))::uuid,
  v.name,
  55.8304 + v.dlat,
  49.1328 + v.dlng,
  v.address,
  v.hours,
  v.hours,
  v.frac,
  true,
  v.descr,
  v.fill,
  '+78432035555',
  'SEED_POINT',
  v.access
from (values
  (1,  'Холл корпуса А',              0.0002,  0.0001, 'ул. Бари Галеева, 3-А, холл',           '08:00–20:00', array['plastic','paper'],                          28, true,  'У входа, рядом с вахтой'),
  (2,  'Эко-остров у столовой',       0.0004, -0.0002, 'ул. Бари Галеева, 3-А, столовая',        '09:00–18:00', array['plastic','paper','glass','metal'],         45, true,  'Контейнеры у обеденной зоны'),
  (3,  'Общежитие №1 — 1 этаж',       0.0010,  0.0005, 'ул. Бари Галеева, общежитие 1',          '09:00–21:00', array['plastic','glass','metal'],                 62, false, 'У лестничной клетки'),
  (4,  'Общежитие №2 — холл',         0.0012,  0.0008, 'ул. Бари Галеева, общежитие 2',          '09:00–21:00', array['plastic','paper','hazardous'],             51, true,  'Рядом с почтовыми ящиками'),
  (5,  'Библиотека — ресепшен',       0.0001, -0.0004, 'Корпус Б, библиотека',                   '09:00–17:00', array['paper'],                                   18, true,  'Только макулатура'),
  (6,  'Актовый зал — фойе',          0.0003,  0.0006, 'Корпус А, актовый зал',                  '10:00–19:00', array['plastic','paper'],                          33, true,  'После мероприятий'),
  (7,  'Спортзал — раздевалка',       0.0008, -0.0006, 'Спортивный корпус',                      '08:00–22:00', array['plastic'],                                  71, false, 'Бутылки после тренировок'),
  (8,  'Лаборатория сетей',           0.0005,  0.0003, 'Корпус В, каб. 214',                     '09:00–16:00', array['metal','hazardous','plastic'],             22, false, 'Для студентов ССАп'),
  (9,  'Парковка у КПП',             -0.0003,  0.0010, 'КПП Бари Галеева',                       '07:00–22:00', array['plastic','metal','glass'],                 40, true,  'Уличная площадка'),
  (10, 'Коворкинг 3 этаж',            0.0000,  0.0002, 'Корпус А, 3 этаж',                       '09:00–20:00', array['paper','plastic'],                          15, true,  'Рядом с принтерами'),
  (11, 'Мастерская электроники',      0.0006, -0.0001, 'Корпус В, мастерская',                   '10:00–17:00', array['metal','hazardous'],                       37, false, 'Батарейки и платы'),
  (12, 'Кафе «Кампус»',               0.0002, -0.0008, 'Двор техникума, кафе',                   '08:30–18:30', array['plastic','glass','metal'],                 58, true,  'Стаканчики и банки'),
  (13, 'Учебный корпус Г — вход',     0.0015,  0.0000, 'ул. Бари Галеева, корпус Г',             '08:00–19:00', array['plastic','paper','glass'],                 29, true,  'Главный вход'),
  (14, 'Медкабинет — холл',           0.0004,  0.0004, 'Корпус А, медпункт',                     '09:00–15:00', array['hazardous'],                               12, true,  'Только батарейки'),
  (15, 'Площадка «Зелёный двор»',    -0.0005, -0.0003, 'Внутренний двор',                        'круглосуточно', array['plastic','paper','glass','metal','hazardous'], 66, true, 'Центральная эко-площадка'),
  (16, 'Секретариат — приёмная',      0.0001,  0.0000, 'Корпус А, 2 этаж',                       '09:00–17:00', array['paper'],                                   8,  true,  'Офисная бумага'),
  (17, 'Серверная — коридор',         0.0007,  0.0002, 'Корпус В, 1 этаж',                       '09:00–18:00', array['metal','hazardous'],                       25, false, 'Электронные отходы'),
  (18, 'Тренажёрный зал',             0.0009, -0.0005, 'Спортивный корпус, 2 этаж',              '07:00–23:00', array['plastic'],                                  74, false, 'Бутылки'),
  (19, 'Музей связи',                 0.0003,  0.0009, 'Корпус Б, музей',                        '10:00–16:00', array['paper','plastic'],                          19, true,  'У выхода'),
  (20, 'Стоянка велосипедов',        -0.0002,  0.0007, 'У велопарковки',                         '06:00–23:00', array['plastic','metal'],                         43, true,  'Уличная точка'),
  (21, 'Каб. программирования 305',   0.0002,  0.0003, 'Корпус А, 305',                          '09:00–18:00', array['paper','plastic'],                          21, false, 'После пар'),
  (22, 'Каб. ИБ 412',                 0.0005, -0.0002, 'Корпус В, 412',                          '09:00–18:00', array['hazardous','metal'],                       16, false, 'Аккумуляторы'),
  (23, 'Буфет 1 этаж',                0.0000, -0.0005, 'Корпус А, буфет',                        '08:00–16:00', array['plastic','glass','metal'],                 69, true,  'Банки и бутылки'),
  (24, 'Холл общежития №3',           0.0014,  0.0011, 'Общежитие 3',                            '09:00–21:00', array['plastic','paper','glass'],                 54, true,  'Ресепшен'),
  (25, 'Площадка у спортплощадки',   -0.0006,  0.0004, 'Стадион техникума',                      '08:00–21:00', array['plastic'],                                  48, true,  'У трибун'),
  (26, 'Архив / канцелярия',          0.0001,  0.0005, 'Корпус Б, архив',                        '10:00–15:00', array['paper'],                                   31, false, 'Картон и документы'),
  (27, 'Мастерская печати',           0.0004, -0.0007, 'Корпус Г, типография',                   '09:00–17:00', array['paper','plastic'],                          27, false, 'Обрезки и плёнка'),
  (28, 'Пункт волонтёров',            0.0003,  0.0001, 'Корпус А, эко-штаб',                     '10:00–18:00', array['plastic','paper','glass','metal','hazardous'], 35, true, 'Приём заявок и взвешивание'),
  (29, 'Крыльцо корпуса Б',          -0.0001, -0.0001, 'Корпус Б, крыльцо',                      '08:00–20:00', array['plastic','glass'],                         57, true,  'Уличная урна-контейнер'),
  (30, 'Парк у техникума',           -0.0010,  0.0012, 'Сквер у Бари Галеева',                   'круглосуточно', array['plastic','paper','glass','metal'],      39, true,  'Общегородская точка рядом с кампусом')
) as v(n, name, dlat, dlng, address, hours, frac, fill, access, descr)
on conflict (id) do update set
  name = excluded.name,
  fill_percent = excluded.fill_percent,
  description = excluded.description;

-- ---------------------------------------------------------------------------
-- 6. challenges → 30 (добавляем к существующим)
-- ---------------------------------------------------------------------------
delete from public.challenges where title like 'SEED:%';
-- (каскадно снимет старые participations/proofs по SEED-челленджам)

insert into public.challenges (
  title, description, challenge_type, reward_points, target_fraction, target_kg, starts_at, ends_at, is_published
)
select
  'SEED:' || lpad(v.n::text, 2, '0') || ' ' || v.title,
  v.descr,
  v.ctype,
  v.pts,
  v.frac,
  v.kg,
  now() - (v.ago || ' days')::interval,
  now() + (v.days_left || ' days')::interval,
  true
from (values
  (1,  'Утренняя макулатура',     'Сдайте 2 кг бумаги до обеда',              'daily',     40,  'paper',     2.0,  1,  2),
  (2,  'Пластиковый вторник',     'Только PET и HDPE — 3 кг',                 'daily',     55,  'plastic',   3.0,  2,  1),
  (3,  'Неделя стекла',           'Банки и бутылки, 4 кг за неделю',          'weekly',    90,  'glass',     4.0,  3, 10),
  (4,  'Металл кампуса',          'Алюминий и жесть — 3 кг',                  'weekly',   110,  'metal',     3.0,  5, 12),
  (5,  'Батарейный сбор',         'Сдайте опасные отходы (0.5 кг)',            'weekly',    70,  'hazardous', 0.5,  4,  9),
  (6,  'Команда ИТ',              'Отделение ИТ: 40 кг вместе',               'team',     220,  'plastic',  40.0,  7, 21),
  (7,  'Команда сетей',           'ССАп/КСКп: 35 кг',                         'team',     200,  null,      35.0,  6, 20),
  (8,  'Команда ИБ',              'ИБ и почтовая связь: 30 кг',               'team',     190,  null,      30.0,  8, 22),
  (9,  'Осенний марафон',         'Сезон: 12 кг любого сырья',                'seasonal', 160,  null,      12.0, 14, 45),
  (10, 'Зимний эко-зачёт',        'Сезон: 8 кг до сессии',                    'seasonal', 140,  null,       8.0, 20, 50),
  (11, 'День без пластика',       'Спецдень: сдайте 1 кг пластика',           'special',   60,  'plastic',   1.0,  0,  3),
  (12, 'Субботник МЦК',           'Общий субботник: 5 кг',                    'special',  100,  null,       5.0, 10,  5),
  (13, 'Первые 500 г',            'Новичкам: любая фракция 0.5 кг',           'individual',30,  null,       0.5,  1, 14),
  (14, 'Бумажный герой недели',   '5 кг макулатуры индивидуально',            'individual',95,  'paper',     5.0,  2, 14),
  (15, 'Алюминиевый спринт',      '2 кг банок за 3 дня',                      'individual',75,  'metal',     2.0,  0,  3),
  (16, 'Стеклянная пятница',      'Только стекло — 2 кг',                     'daily',     45,  'glass',     2.0,  4,  2),
  (17, 'Чистый холл',             'Сдайте пластик из корпуса А',              'weekly',    80,  'plastic',   4.0,  3, 11),
  (18, 'Общага зовёт',            'Студенты общежитий: 25 кг',                 'team',     180,  null,      25.0,  9, 18),
  (19, 'Эко-сессия',              'Перед экзаменами: 6 кг',                   'seasonal', 130,  null,       6.0, 12, 30),
  (20, 'Зелёный курс',            '1 курс: общий зачёт 20 кг',                'team',     150,  null,      20.0,  5, 25),
  (21, 'Вторник металла',         'Металл 1.5 кг за день',                    'daily',     50,  'metal',     1.5,  1,  1),
  (22, 'Неделя батареек',         'Кампус сдаёт опасные отходы',              'weekly',    85,  'hazardous', 1.0,  6, 10),
  (23, 'Флешмоб стекла',          'Спец: 3 кг стекла',                        'special',   70,  'glass',     3.0,  2,  4),
  (24, 'Личный рекорд',           'Индивидуально 7 кг',                       'individual',120, null,       7.0,  8, 21),
  (25, 'Весенний двор',           'Уборка двора + сдача 4 кг',                'seasonal', 155,  null,       4.0, 15, 40),
  (26, 'Пластик vs бумага',       'Сдайте 3 кг бумаги ИЛИ пластика',          'weekly',    88,  null,       3.0,  3, 12),
  (27, 'Ночная смена волонтёров', 'Для staff: 2 кг после 18:00',              'special',   65,  null,       2.0,  1,  7),
  (28, 'Месяц без отходов',       'Долгий трек: 15 кг',                       'seasonal', 210,  null,      15.0, 25, 60),
  (29, 'Кубок отделений',         'Межотделенческий зачёт 60 кг',             'team',     300,  null,      60.0, 10, 28),
  (30, 'Финиш семестра',          'Закрыть семестр 10 кг лично',              'individual',135, null,      10.0, 18, 35)
) as v(n, title, descr, ctype, pts, frac, kg, ago, days_left);

-- ---------------------------------------------------------------------------
-- 7. achievements → довести до 30
-- ---------------------------------------------------------------------------
insert into public.achievements (code, title, description, icon_url, title_ru, description_ru, icon)
values
  ('seed_early_bird', 'Ранняя пташка', 'Сдача до 10:00', 'wb_sunny', 'Ранняя пташка', 'Сдача до 10:00', 'wb_sunny'),
  ('seed_night_owl', 'Ночная смена', 'Сдача после 20:00', 'nightlight', 'Ночная смена', 'Сдача после 20:00', 'nightlight'),
  ('seed_dorm', 'Общажный активист', '10 сдач из общежития', 'home', 'Общажный активист', '10 сдач из общежития', 'home'),
  ('seed_canteen', 'Столовый герой', '5 сдач у столовой', 'restaurant', 'Столовый герой', '5 сдач у столовой', 'restaurant'),
  ('seed_photo', 'Фоторепортёр', '10 фото-заявок', 'photo_camera', 'Фоторепортёр', '10 фото-заявок', 'photo_camera'),
  ('seed_qr', 'QR-чемпион', '15 сдач через QR', 'qr_code', 'QR-чемпион', '15 сдач через QR', 'qr_code'),
  ('seed_streak7', 'Неделя подряд', '7 дней активности', 'local_fire_department', 'Неделя подряд', '7 дней активности', 'local_fire_department'),
  ('seed_streak14', 'Две недели', '14 дней активности', 'whatshot', 'Две недели', '14 дней активности', 'whatshot'),
  ('seed_kg25', 'Четверть центнера', '25 кг суммарно', 'scale', 'Четверть центнера', '25 кг суммарно', 'scale'),
  ('seed_kg75', 'Три четверти', '75 кг суммарно', 'fitness_center', 'Три четверти', '75 кг суммарно', 'fitness_center'),
  ('seed_points500', 'Полтысячи баллов', '500 зелёных баллов', 'stars', 'Полтысячи баллов', '500 зелёных баллов', 'stars'),
  ('seed_points1000', 'Тысячник', '1000 зелёных баллов', 'military_tech', 'Тысячник', '1000 зелёных баллов', 'military_tech'),
  ('seed_co2_50', 'CO₂ −50 кг', 'Сэкономлено 50 кг CO₂', 'cloud', 'CO₂ −50 кг', 'Сэкономлено 50 кг CO₂', 'cloud'),
  ('seed_faculty', 'Гордость отделения', 'Топ-3 отделения', 'school', 'Гордость отделения', 'Топ-3 отделения', 'school'),
  ('seed_mentor', 'Наставник', 'Помог новичку со сдачей', 'handshake', 'Наставник', 'Помог новичку со сдачей', 'handshake'),
  ('seed_dispute_fair', 'Честный спор', 'Выигранный спор по баллам', 'gavel', 'Честный спор', 'Выигранный спор по баллам', 'gavel'),
  ('seed_map', 'Картограф', '5 избранных пунктов', 'map', 'Картограф', '5 избранных пунктов', 'map'),
  ('seed_clean_friday', 'Чистая пятница', 'Участие в субботнике', 'cleaning_services', 'Чистая пятница', 'Участие в субботнике', 'cleaning_services')
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- 8. recycling_submissions (30)
-- ---------------------------------------------------------------------------
delete from public.recycling_submissions s
using public.profiles p
where s.student_id = p.id and p.email like 'seed%@mck-ktits.demo';

insert into public.recycling_submissions (
  student_id, category_id, collection_point_id, subcategory_id,
  method, status, weight_kg, points_awarded, co2_awarded, bonus_multiplier,
  note, latitude, longitude, submitted_at, verified_at, reviewer_note
)
select
  u.id,
  c.id,
  cp.id,
  sc.id,
  v.method,
  v.status,
  v.weight,
  case when v.status = 'verified' then round(v.weight * c.points_per_kg * v.mult)::int else 0 end,
  case when v.status = 'verified' then round(v.weight * c.co2_per_kg * v.mult, 2) else 0 end,
  v.mult,
  v.note,
  55.8304 + (v.n * 0.00005),
  49.1328 + (v.n * 0.00004),
  now() - (v.ago || ' days')::interval - (v.n || ' hours')::interval,
  case when v.status = 'verified' then now() - ((v.ago - 1) || ' days')::interval else null end,
  case v.status
    when 'verified' then 'Вес подтверждён на пункте'
    when 'rejected' then 'Фото нечитаемое / вес завышен'
    else null
  end
from (values
  (1,  'plastic',   'pet',        'photo_claim', 'verified', 2.4, 1.0,  'Бутылки после пары',           2),
  (2,  'paper',     'office',     'qr_scan',     'verified', 3.1, 1.0,  'Макулатура из каб. 305',       3),
  (3,  'glass',     'bottles',    'photo_claim', 'pending',  1.8, 1.0,  'Банки из буфета',              1),
  (4,  'metal',     'alu_cans',   'qr_scan',     'verified', 1.2, 1.1,  'Алюминий, акция ×1.1',        4),
  (5,  'hazardous', 'aa',         'photo_claim', 'verified', 0.4, 1.0,  'Пальчиковые батарейки',        5),
  (6,  'plastic',   'hdpe',       'qr_scan',     'verified', 2.0, 1.0,  'Флаконы',                     6),
  (7,  'paper',     'cardboard',  'photo_claim', 'rejected', 5.0, 1.0,  'Картон без взвешивания',       2),
  (8,  'plastic',   'pp',         'iot',         'verified', 0.9, 1.0,  'Умный контейнер коворкинга',   7),
  (9,  'glass',     'jars',       'qr_scan',     'verified', 2.5, 1.0,  'Банки из кафе',               8),
  (10, 'metal',     'tin',        'photo_claim', 'pending',  1.5, 1.0,  'Жесть',                       3),
  (11, 'paper',     'notebooks',  'photo_claim', 'verified', 4.2, 1.0,  'Старые тетради после сессии',  9),
  (12, 'plastic',   'ldpe',       'qr_scan',     'verified', 1.1, 1.0,  'Пакеты',                      4),
  (13, 'hazardous', 'accum',      'photo_claim', 'verified', 0.8, 1.0,  'Аккумуляторы от ноутбуков',   10),
  (14, 'plastic',   'pet',        'qr_scan',     'verified', 3.3, 1.2,  'Субботник ×1.2',             11),
  (15, 'paper',     'magazines',  'photo_claim', 'pending',  2.2, 1.0,  'Журналы из библиотеки',        1),
  (16, 'glass',     'cullet',     'photo_claim', 'rejected', 3.0, 1.0,  'Бой — не приняли',            5),
  (17, 'metal',     'foil',       'qr_scan',     'verified', 0.6, 1.0,  'Фольга из буфета',            6),
  (18, 'plastic',   'other',      'photo_claim', 'verified', 1.7, 1.0,  'Смешанный пластик',           8),
  (19, 'paper',     'books',      'qr_scan',     'verified', 6.0, 1.0,  'Списанные учебники',         12),
  (20, 'hazardous', 'button',     'photo_claim', 'pending',  0.2, 1.0,  'Кроны',                       2),
  (21, 'plastic',   'caps',       'iot',         'verified', 0.5, 1.0,  'Крышки — акция',              7),
  (22, 'glass',     'perfume',    'photo_claim', 'verified', 1.0, 1.0,  'Флаконы',                     9),
  (23, 'metal',     'scrap',      'qr_scan',     'verified', 2.8, 1.0,  'Мелкий металлолом',          13),
  (24, 'paper',     'tetra',      'photo_claim', 'pending',  1.4, 1.0,  'Тетрапак',                    3),
  (25, 'plastic',   'film',       'qr_scan',     'verified', 0.7, 1.0,  'Плёнка из типографии',       14),
  (26, 'hazardous', 'lamps',      'photo_claim', 'verified', 0.3, 1.0,  'Ртутные лампы (запакованы)', 15),
  (27, 'plastic',   'ps',         'photo_claim', 'rejected', 2.1, 1.0,  'Грязные стаканчики',          4),
  (28, 'paper',     'office',     'qr_scan',     'verified', 2.9, 1.0,  'Документы секретариата',     16),
  (29, 'metal',     'alu_cans',   'photo_claim', 'verified', 1.9, 1.0,  'Банки после мероприятия',    12),
  (30, 'glass',     'bottles',    'qr_scan',     'verified', 3.4, 1.0,  'Бутылки с площадки двора',   15)
) as v(n, fraction, subcode, method, status, weight, mult, note, ago)
join public._seed_uids u on u.n = v.n
join public.waste_categories c on c.fraction = v.fraction
left join public.waste_subcategories sc on sc.category_id = c.id and sc.code = v.subcode
join public.collection_points cp
  on cp.id = ('c3000000-0000-4000-8000-' || lpad((((v.n - 1) % 30) + 1)::text, 12, '0'))::uuid;

-- ---------------------------------------------------------------------------
-- 9. challenge_participations (30)
-- ---------------------------------------------------------------------------
delete from public.challenge_participations cp
using public._seed_uids u
where cp.user_id = u.id;

insert into public.challenge_participations (
  challenge_id, user_id, status, progress_kg, joined_at, completed_at, abandoned_at
)
select
  ch.id,
  u.id,
  v.status,
  v.progress,
  now() - (v.ago || ' days')::interval,
  case when v.status = 'completed' then now() - ((v.ago - 2) || ' days')::interval else null end,
  case when v.status = 'abandoned' then now() - ((v.ago - 1) || ' days')::interval else null end
from (values
  (1,  1,  'completed', 2.4, 5),
  (2,  2,  'active',    1.1, 2),
  (3,  3,  'active',    2.0, 4),
  (4,  4,  'completed', 3.2, 8),
  (5,  5,  'active',    0.3, 3),
  (6,  6,  'active',    12.0, 7),
  (7,  7,  'abandoned', 0.5, 10),
  (8,  8,  'active',    4.5, 6),
  (9,  9,  'completed', 12.5, 15),
  (10, 10, 'active',    0.0, 1),
  (11, 11, 'completed', 1.2, 2),
  (12, 12, 'active',    2.1, 5),
  (13, 13, 'completed', 0.8, 4),
  (14, 14, 'active',    3.0, 6),
  (15, 15, 'completed', 2.2, 3),
  (16, 16, 'active',    0.9, 1),
  (17, 17, 'active',    1.5, 4),
  (18, 18, 'completed', 6.0, 9),
  (19, 19, 'active',    2.4, 8),
  (20, 20, 'active',    5.5, 11),
  (21, 21, 'completed', 1.6, 2),
  (22, 22, 'active',    0.4, 5),
  (23, 23, 'abandoned', 0.2, 7),
  (24, 24, 'active',    3.8, 6),
  (25, 25, 'completed', 4.1, 12),
  (26, 26, 'active',    1.0, 3),
  (27, 27, 'active',    0.7, 2),
  (28, 28, 'active',    6.2, 14),
  (29, 29, 'active',    8.0, 10),
  (30, 30, 'active',    4.4, 9)
) as v(n, ch_n, status, progress, ago)
join public._seed_uids u on u.n = v.n
join public.challenges ch
  on ch.title like 'SEED:' || lpad(v.ch_n::text, 2, '0') || ' %'
on conflict (challenge_id, user_id) do nothing;

-- ---------------------------------------------------------------------------
-- 10. user_achievements (30)
-- ---------------------------------------------------------------------------
delete from public.user_achievements ua
using public._seed_uids u
where ua.user_id = u.id;

insert into public.user_achievements (user_id, achievement_id, earned_at)
select
  u.id,
  a.id,
  now() - (v.ago || ' days')::interval
from (values
  (1,  'first_step', 20),
  (2,  'first_step', 10),
  (3,  'eco_novice', 18),
  (4,  'first_step', 12),
  (5,  'seed_photo', 8),
  (6,  'forest_keeper', 25),
  (6,  'seed_points500', 15),
  (7,  'first_step', 5),
  (8,  'eco_novice', 14),
  (9,  'plastic_warrior', 16),
  (11, 'first_step', 9),
  (12, 'first_step', 4),
  (13, 'forest_keeper', 22),
  (13, 'seed_qr', 11),
  (14, 'seed_early_bird', 7),
  (15, 'eco_master', 28),
  (15, 'seed_points1000', 20),
  (16, 'paper_hero', 13),
  (18, 'eco_novice', 17),
  (19, 'first_step', 6),
  (20, 'eco_master', 24),
  (20, 'seed_co2_50', 19),
  (21, 'first_step', 3),
  (22, 'seed_streak7', 10),
  (23, 'first_step', 8),
  (24, 'seed_mentor', 5),
  (25, 'metal_lord', 21),
  (27, 'glass_guard', 12),
  (28, 'seed_dorm', 9),
  (30, 'forest_keeper', 18)
) as v(n, code, ago)
join public._seed_uids u on u.n = v.n
join public.achievements a on a.code = v.code
on conflict (user_id, achievement_id) do nothing;

-- ---------------------------------------------------------------------------
-- 11. challenge_proofs (30)
-- ---------------------------------------------------------------------------
delete from public.challenge_proofs pf
using public._seed_uids u
where pf.user_id = u.id;

insert into public.challenge_proofs (
  challenge_id, user_id, photo_url, comment, status, reviewer_note, created_at
)
select
  ch.id,
  u.id,
  'https://placehold.co/600x400/png?text=eco-proof-' || v.n,
  v.comment,
  v.status,
  case v.status
    when 'approved' then 'Фото принято'
    when 'rejected' then 'Не видно весов / дата'
    else null
  end,
  now() - (v.ago || ' days')::interval
from (values
  (1,  1,  'approved', 'Взвесили на пункте у столовой', 4),
  (2,  2,  'pending',  'PET из общежития', 1),
  (3,  3,  'approved', 'Стекло после мероприятия', 5),
  (4,  4,  'rejected', 'Размытое фото', 3),
  (5,  5,  'pending',  'Батарейки в пакете', 2),
  (6,  6,  'approved', 'Командная сдача ИТ', 6),
  (7,  7,  'rejected', 'Не тот челлендж', 8),
  (8,  8,  'pending',  'Металл с парковки', 2),
  (9,  9,  'approved', 'Сезонный зачёт', 10),
  (10, 11, 'pending',  'Первая заявка', 1),
  (11, 12, 'approved', 'Макулатура 1 курса', 3),
  (12, 13, 'approved', 'Субботник', 7),
  (13, 14, 'pending',  'Волонтёрская смена', 2),
  (14, 15, 'approved', 'Личный рекорд', 9),
  (15, 16, 'pending',  'Бумага из библиотеки', 1),
  (16, 17, 'rejected', 'Нет бирки веса', 4),
  (17, 18, 'approved', 'Стекло кафе', 5),
  (18, 19, 'pending',  'Пластик коворкинга', 2),
  (19, 20, 'approved', 'Сессия — макулатура', 11),
  (20, 21, 'pending',  'Новичок', 1),
  (21, 22, 'approved', 'ИБ-кабинет', 6),
  (22, 23, 'pending',  'Жесть', 3),
  (23, 24, 'approved', 'Пруф для модерации', 4),
  (24, 25, 'approved', 'Металл мастерской', 8),
  (25, 26, 'pending',  'Двор', 2),
  (26, 27, 'approved', 'Сети — командный', 7),
  (27, 28, 'pending',  'Вечерняя сдача', 1),
  (28, 29, 'rejected', 'Повтор фото', 5),
  (29, 30, 'approved', 'Финиш семестра', 12),
  (30, 1,  'pending',  'Досбор пластика', 0)
) as v(n, user_n, status, comment, ago)
join public._seed_uids u on u.n = v.user_n
join public.challenges ch
  on ch.title like 'SEED:' || lpad((((v.n - 1) % 30) + 1)::text, 2, '0') || ' %';

-- ---------------------------------------------------------------------------
-- 12. redeem_requests (30)
-- ---------------------------------------------------------------------------
delete from public.redeem_requests r
using public._seed_uids u
where r.student_id = u.id;

insert into public.redeem_requests (student_id, reward_code, reward_title, points_cost, status, created_at)
select
  u.id,
  v.code,
  v.title,
  v.cost,
  v.status,
  now() - (v.ago || ' days')::interval
from (values
  (1,  'coffee',      'Кофе в буфете',                 80,  'fulfilled', 12),
  (2,  'sticker',     'Эко-стикер МЦК',                40,  'approved',   3),
  (3,  'merch_tee',   'Футболка Eco-Treker',          400,  'pending',    1),
  (4,  'canteen_10',  'Скидка 10% в столовой',        120,  'fulfilled', 15),
  (5,  'badge',       'Значок волонтёра',             100,  'fulfilled', 20),
  (6,  'powerbank',   'Power bank 5000 mAh',          600,  'approved',   5),
  (7,  'sticker',     'Эко-стикер МЦК',                40,  'rejected',   8),
  (8,  'notebook',    'Блокнот из вторсырья',         150,  'fulfilled', 11),
  (9,  'bus_ticket',  'Проездной на день',            200,  'pending',    2),
  (11, 'coffee',      'Кофе в буфете',                 80,  'fulfilled',  9),
  (12, 'sticker',     'Эко-стикер МЦК',                40,  'pending',    1),
  (13, 'merch_hoodie','Худи Eco-Treker',              800,  'approved',   4),
  (14, 'badge',       'Значок волонтёра',             100,  'fulfilled', 14),
  (15, 'plant',       'Росток в горшке',              250,  'fulfilled', 18),
  (16, 'canteen_10',  'Скидка 10% в столовой',        120,  'pending',    2),
  (17, 'coffee',      'Кофе в буфете',                 80,  'rejected',   6),
  (18, 'notebook',    'Блокнот из вторсырья',         150,  'fulfilled', 10),
  (19, 'sticker',     'Эко-стикер МЦК',                40,  'approved',   3),
  (20, 'powerbank',   'Power bank 5000 mAh',          600,  'fulfilled', 22),
  (21, 'coffee',      'Кофе в буфете',                 80,  'pending',    1),
  (22, 'bus_ticket',  'Проездной на день',            200,  'approved',   4),
  (23, 'badge',       'Значок волонтёра',             100,  'pending',    2),
  (24, 'sticker',     'Эко-стикер МЦК',                40,  'fulfilled',  7),
  (25, 'merch_tee',   'Футболка Eco-Treker',          400,  'fulfilled', 16),
  (26, 'canteen_10',  'Скидка 10% в столовой',        120,  'pending',    1),
  (27, 'notebook',    'Блокнот из вторсырья',         150,  'approved',   5),
  (28, 'plant',       'Росток в горшке',              250,  'pending',    2),
  (29, 'coffee',      'Кофе в буфете',                 80,  'fulfilled', 13),
  (30, 'merch_hoodie','Худи Eco-Treker',              800,  'pending',    1),
  (6,  'coffee',      'Кофе в буфете',                 80,  'fulfilled', 30)
) as v(n, code, title, cost, status, ago)
join public._seed_uids u on u.n = v.n;

-- ---------------------------------------------------------------------------
-- 13. bin_reports (30)
-- ---------------------------------------------------------------------------
delete from public.bin_reports br
using public._seed_uids u
where br.reporter_id = u.id;

insert into public.bin_reports (reporter_id, collection_point_id, note, status, created_at)
select
  u.id,
  cp.id,
  v.note,
  v.status,
  now() - (v.ago || ' days')::interval
from (values
  (1,  'open',         'Пластик переполнен у столовой', 1),
  (2,  'acknowledged', 'Нет места для бумаги в библиотеке', 2),
  (3,  'resolved',     'Убрали стекло у КПП', 5),
  (4,  'open',         'Контейнер в общаге 2 почти полный', 0),
  (5,  'acknowledged', 'Батарейки: коробка забита', 3),
  (6,  'resolved',     'Починили крышку у холла А', 8),
  (7,  'open',         'Пакеты валяются рядом с точкой', 1),
  (8,  'open',         'Металл не принимают — нет отсека', 2),
  (9,  'acknowledged', 'Запах у спортзала', 4),
  (11, 'resolved',     'Очистили двор', 10),
  (12, 'open',         'Макулатура выпирает', 1),
  (13, 'acknowledged', 'Нужен вывоз с парковки', 3),
  (14, 'open',         'Очередь у пункта волонтёров', 0),
  (15, 'resolved',     'Заменили контейнер в кафе', 7),
  (16, 'open',         'Нет пакетов для опасных отходов', 2),
  (17, 'acknowledged', 'Серверная: полный ящик электроники', 5),
  (18, 'open',         'Бутылки у тренажёрки', 1),
  (19, 'resolved',     'Убрали у музея', 9),
  (20, 'open',         'Велопарковка переполнена пластиком', 2),
  (21, 'acknowledged', 'Каб. 305 — полный ящик бумаги', 3),
  (22, 'open',         'ИБ 412: батарейки на полу', 1),
  (23, 'resolved',     'Буфет вывезли', 6),
  (24, 'open',         'Общага 3 — стекло', 0),
  (25, 'acknowledged', 'Стадион после матча', 2),
  (26, 'open',         'Архив: картон до потолка', 4),
  (27, 'resolved',     'Типография: вывезли плёнку', 11),
  (28, 'open',         'Нужна смена втулок', 1),
  (29, 'acknowledged', 'Крыльцо Б мокрое, контейнер полный', 3),
  (30, 'open',         'Сквер: пакеты вокруг урны', 1),
  (10, 'resolved',     'Админ отметил вывоз', 12)
) as v(n, status, note, ago)
join public._seed_uids u on u.n = v.n
join public.collection_points cp
  on cp.id = ('c3000000-0000-4000-8000-' || lpad((((v.n - 1) % 30) + 1)::text, 12, '0'))::uuid;

-- ---------------------------------------------------------------------------
-- 14. point_disputes (30)
-- ---------------------------------------------------------------------------
delete from public.point_disputes d
using public._seed_uids u
where d.student_id = u.id;

insert into public.point_disputes (student_id, submission_id, reason, status, created_at)
select
  u.id,
  s.id,
  v.reason,
  v.status,
  now() - (v.ago || ' days')::interval
from (values
  (1,  'open',     'Вес занизили на 0.3 кг', 2),
  (2,  'resolved', 'Баллы начислили после проверки фото', 5),
  (3,  'open',     'Не учли бонус субботника', 1),
  (4,  'rejected', 'Фото не подтверждает вес', 4),
  (5,  'open',     'Категория должна быть metal, не plastic', 1),
  (6,  'resolved', 'Пересчитали коэффициент', 8),
  (7,  'open',     'Отклонили без комментария', 0),
  (8,  'resolved', 'IoT-контейнер ошибся', 6),
  (9,  'open',     'Дубль заявки сняли не ту', 2),
  (11, 'rejected', 'Спор без оснований', 3),
  (12, 'open',     'Не пришли баллы за макулатуру', 1),
  (13, 'resolved', 'QR отсканировали дважды — поправили', 7),
  (14, 'open',     'Волонтёр указал неверный вес', 2),
  (15, 'resolved', 'Начислили ретроактивно', 10),
  (16, 'open',     'Статус pending слишком долго', 3),
  (17, 'rejected', 'Вес меньше минимума', 5),
  (18, 'open',     'Неверный пункт сбора в заявке', 1),
  (19, 'resolved', 'Фото приняли после уточнения', 4),
  (20, 'open',     'Не хватает 50 баллов до худи', 2),
  (21, 'open',     'Первая сдача без баллов', 1),
  (22, 'resolved', 'Исправлена фракция hazardous', 6),
  (23, 'open',     'Отклонили картон без причины', 0),
  (24, 'resolved', 'Модератор подтвердил', 3),
  (25, 'open',     'Металл взвесили без тары', 2),
  (26, 'rejected', 'Повторный спор', 4),
  (27, 'open',     'Не учли крышки PET', 1),
  (28, 'resolved', 'Баллы за сессию доначислили', 9),
  (29, 'open',     'Путаница с чужой заявкой', 2),
  (30, 'open',     'Не вижу начисление за двор', 1),
  (10, 'resolved', 'Админ закрыл спор', 11)
) as v(n, status, reason, ago)
join public._seed_uids u on u.n = v.n
left join lateral (
  select id from public.recycling_submissions
  where student_id = u.id
  order by submitted_at desc
  limit 1
) s on true;

-- ---------------------------------------------------------------------------
-- 15. favorites_points (30)
-- ---------------------------------------------------------------------------
delete from public.favorites_points fp
using public._seed_uids u
where fp.user_id = u.id;

insert into public.favorites_points (user_id, collection_point_id, created_at)
select
  u.id,
  cp.id,
  now() - (v.ago || ' days')::interval
from (values
  (1, 1, 10), (1, 2, 9), (2, 3, 8), (3, 4, 7), (3, 15, 6),
  (4, 5, 5), (5, 28, 4), (6, 2, 12), (6, 15, 11), (7, 1, 3),
  (8, 10, 4), (9, 9, 5), (11, 12, 2), (12, 1, 1), (13, 15, 8),
  (14, 28, 6), (15, 2, 14), (16, 5, 3), (17, 7, 2), (18, 12, 7),
  (19, 10, 4), (20, 15, 15), (21, 3, 1), (22, 22, 5), (23, 24, 3),
  (24, 28, 4), (25, 11, 9), (27, 8, 6), (28, 6, 5), (30, 30, 8)
) as v(user_n, point_n, ago)
join public._seed_uids u on u.n = v.user_n
join public.collection_points cp
  on cp.id = ('c3000000-0000-4000-8000-' || lpad(v.point_n::text, 12, '0'))::uuid
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- 16. otp_attempts (30)
-- ---------------------------------------------------------------------------
delete from public.otp_attempts where phone like '+79061234%';

insert into public.otp_attempts (phone, attempts, locked_until, updated_at)
select
  sp.phone,
  case when sp.n % 7 = 0 then 5 else sp.n % 4 end,
  case when sp.n % 7 = 0 then now() + interval '10 minutes' else null end,
  now() - (sp.n || ' hours')::interval
from public._seed_people sp
on conflict (phone) do update set
  attempts = excluded.attempts,
  locked_until = excluded.locked_until,
  updated_at = excluded.updated_at;

-- ---------------------------------------------------------------------------
-- 17. phone_otps (30) — если таблица есть
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.phone_otps') is not null then
    delete from public.phone_otps where phone like '+79061234%';
    insert into public.phone_otps (phone, code, attempts, locked_until, expires_at, updated_at)
    select
      sp.phone,
      lpad(((100000 + sp.n * 137) % 1000000)::text, 6, '0'),
      sp.n % 3,
      null,
      now() + interval '10 minutes',
      now()
    from public._seed_people sp
    on conflict (phone) do update set
      code = excluded.code,
      attempts = excluded.attempts,
      expires_at = excluded.expires_at,
      updated_at = excluded.updated_at;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- Итог
-- ---------------------------------------------------------------------------
select
  'profiles' as tbl, count(*)::int as seed_rows from public.profiles where email like 'seed%@mck-ktits.demo'
union all select 'faculties', count(*) from public.faculties where short_name like 'SEED%'
union all select 'groups', count(*) from public.groups where id::text like 'b2000000%'
union all select 'collection_points', count(*) from public.collection_points where contact_name = 'SEED_POINT'
union all select 'challenges', count(*) from public.challenges where title like 'SEED:%'
union all select 'recycling_submissions', count(*) from public.recycling_submissions s join public.profiles p on p.id = s.student_id where p.email like 'seed%@mck-ktits.demo'
union all select 'challenge_participations', count(*) from public.challenge_participations cp join public.profiles p on p.id = cp.user_id where p.email like 'seed%@mck-ktits.demo'
union all select 'user_achievements', count(*) from public.user_achievements ua join public.profiles p on p.id = ua.user_id where p.email like 'seed%@mck-ktits.demo'
union all select 'challenge_proofs', count(*) from public.challenge_proofs pf join public.profiles p on p.id = pf.user_id where p.email like 'seed%@mck-ktits.demo'
union all select 'redeem_requests', count(*) from public.redeem_requests r join public.profiles p on p.id = r.student_id where p.email like 'seed%@mck-ktits.demo'
union all select 'bin_reports', count(*) from public.bin_reports br join public.profiles p on p.id = br.reporter_id where p.email like 'seed%@mck-ktits.demo'
union all select 'point_disputes', count(*) from public.point_disputes d join public.profiles p on p.id = d.student_id where p.email like 'seed%@mck-ktits.demo'
union all select 'favorites_points', count(*) from public.favorites_points fp join public.profiles p on p.id = fp.user_id where p.email like 'seed%@mck-ktits.demo'
union all select 'otp_attempts', count(*) from public.otp_attempts where phone like '+79061234%'
union all select 'achievements_total', count(*) from public.achievements
union all select 'waste_subcategories_total', count(*) from public.waste_subcategories
order by 1;

-- cleanup staging
drop table if exists public._seed_uids;
drop table if exists public._seed_people;
