begin;
create extension if not exists pgtap;

select plan(5);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000031', 'gas-owner@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000032', 'gas-outsider@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000031', 'role', 'authenticated')::text,
  true
);
select (public.create_group('gaspriv', array[]::text[], false, null)->>'id')::uuid as gas_id \gset

-- 非メンバーは活動統計を見られない
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000032', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  format('select public.get_group_activity_stats(%L::uuid, 4)', :'gas_id'),
  '42501',
  'アクセス権がありません',
  '非メンバーは非公開グループの活動統計を見られない'
);

-- オーナーが今週2件、3週間前に1件投稿する(3週間前の分はUPDATEでcreated_atを遡らせる)
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000031', 'role', 'authenticated')::text,
  true
);
select (public.create_group_post(:'gas_id'::uuid, '今週1件目')->>'id')::uuid as post1_id \gset
select (public.create_group_post(:'gas_id'::uuid, '今週2件目')->>'id')::uuid as post2_id \gset
select (public.create_group_post(:'gas_id'::uuid, '3週間前の投稿')->>'id')::uuid as post3_id \gset

reset role;
update public.group_posts set created_at = now() - interval '3 weeks' where id = :'post3_id';
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000031', 'role', 'authenticated')::text,
  true
);

select public.get_group_activity_stats(:'gas_id'::uuid, 4) as stats \gset

select is(
  jsonb_array_length((:'stats'::jsonb) -> 'weeklyPostCounts'),
  4,
  'p_weeks=4で4週分のバケットが返る'
);

select is(
  (((:'stats'::jsonb) -> 'weeklyPostCounts' -> 0 ->> 'count')::int),
  1,
  '最も古いバケット(3週間前)に1件計上される'
);

select is(
  (((:'stats'::jsonb) -> 'weeklyPostCounts' -> 3 ->> 'count')::int),
  2,
  '最新バケット(今週)に2件計上される'
);

select is(
  ((:'stats'::jsonb) ->> 'repeatRate')::numeric,
  1.00::numeric,
  '2週にまたがって投稿した唯一の投稿者がいるためリピート率は100%'
);

select * from finish();
rollback;
