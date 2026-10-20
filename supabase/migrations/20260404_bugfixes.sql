-- Bugfixes: unique leaderboard places + repair garbled admin/volunteer names

-- Sequential places (1,2,3…) instead of RANK() ties that leave almost everyone as «2»
create or replace view public.leaderboard_students as
select
  p.id,
  p.full_name,
  p.green_points,
  p.total_kg,
  p.group_name,
  p.faculty_name as faculty_short,
  row_number() over (order by p.green_points desc, p.full_name asc) as rank
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
  row_number() over (order by sum(p.green_points) desc, coalesce(p.group_name, '') asc) as rank
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
  row_number() over (order by sum(p.green_points) desc, coalesce(p.faculty_name, '') asc) as rank
from public.profiles p
where p.deleted_at is null and p.role = 'student' and p.faculty_name is not null
group by p.faculty_name;

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
         row_number() over (order by b.score desc, b.title asc) as rank
  from base b
  order by rank
  limit 100;
$$;

-- Repair names that were stored as ???? / empty / English defaults for staff
update public.profiles
set full_name = case role
  when 'admin' then 'Администратор'
  when 'volunteer' then 'Волонтёр'
  else full_name
end
where role in ('admin', 'volunteer')
  and (
    full_name is null
    or btrim(full_name) = ''
    or full_name in ('Student', 'Admin', 'admin', 'Volunteer', 'volunteer')
    or full_name ~ '^\?+$'
    or full_name ~ '^[\uFFFD]+$'
  );
