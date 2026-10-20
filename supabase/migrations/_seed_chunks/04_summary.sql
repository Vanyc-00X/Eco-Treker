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
