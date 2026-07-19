begin;
create extension if not exists pgtap;

select plan(5);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000011', 'gp-owner@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000012', 'gp-outsider@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000011', 'role', 'authenticated')::text,
  true
);
select (public.create_group('gppub', array[]::text[], true, null)->>'id')::uuid as gppub_id \gset
select (public.create_group('gppriv', array[]::text[], false, null)->>'id')::uuid as gppriv_id \gset

-- 非メンバーでも公開グループには投稿できる
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000012', 'role', 'authenticated')::text,
  true
);
select lives_ok(
  format('select public.create_group_post(%L::uuid, %L)', :'gppub_id', 'こんにちは'),
  '非メンバーでも公開グループには投稿できる'
);

-- 非メンバーは非公開グループには投稿できない
select throws_ok(
  format('select public.create_group_post(%L::uuid, %L)', :'gppriv_id', 'こんにちは'),
  '42501',
  'アクセス権がありません',
  '非メンバーは非公開グループに投稿できない'
);

-- オーナーが返信する
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000011', 'role', 'authenticated')::text,
  true
);
select (public.create_group_post(:'gppub_id'::uuid, 'こんにちは')->>'id')::uuid as root_post_id \gset

select lives_ok(
  format('select public.create_group_post(%L::uuid, %L, %L::uuid)', :'gppub_id', '返信です', :'root_post_id'),
  '投稿への1階層の返信ができる'
);

select (public.create_group_post(:'gppub_id'::uuid, '返信への返信の元', :'root_post_id')->>'id')::uuid as reply_id \gset

select throws_ok(
  format('select public.create_group_post(%L::uuid, %L, %L::uuid)', :'gppub_id', '返信への返信', :'reply_id'),
  '22023',
  '返信への返信はできません',
  '返信への返信は拒否される'
);

select is(
  (select count(*) from jsonb_array_elements(public.get_group_posts(:'gppub_id'::uuid)))::int,
  2,
  'get_group_postsはトップレベル投稿のみをトップに返す(返信はrepliesにネスト)'
);

select * from finish();
rollback;
