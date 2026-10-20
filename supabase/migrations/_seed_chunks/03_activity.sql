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

