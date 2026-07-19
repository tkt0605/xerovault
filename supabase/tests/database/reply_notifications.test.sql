begin;
create extension if not exists pgtap;

select plan(4);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000041', 'rn-author@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000042', 'rn-replier@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;

-- 投稿者が元投稿を作成
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000041', 'role', 'authenticated')::text,
  true
);
select (public.create_group('rnpub', array[]::text[], true, null)->>'id')::uuid as rn_group_id \gset
select (public.create_group_post(:'rn_group_id'::uuid, '元投稿')->>'id')::uuid as rn_root_id \gset

-- 自分自身への返信は通知しない
select public.create_group_post(:'rn_group_id'::uuid, '自己返信', :'rn_root_id');

select is(
  (select count(*) from jsonb_array_elements(public.get_my_notifications(30)) n where n ->> 'kind' = 'reply')::int,
  0,
  '自分自身の投稿への返信は通知されない'
);

-- 別ユーザーが返信すると、元投稿の投稿者に通知が届く
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000042', 'role', 'authenticated')::text,
  true
);
select public.create_group_post(:'rn_group_id'::uuid, '他人からの返信', :'rn_root_id');

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000041', 'role', 'authenticated')::text,
  true
);

select is(
  (select count(*) from jsonb_array_elements(public.get_my_notifications(30)) n where n ->> 'kind' = 'reply')::int,
  1,
  '他人からの返信は元投稿者に通知される'
);

select is(
  (
    select n -> 'replyText' from jsonb_array_elements(public.get_my_notifications(30)) n
    where n ->> 'kind' = 'reply'
  )::text,
  '"他人からの返信"',
  '通知に返信本文が含まれる'
);

select is(
  (
    select n -> 'replierName' from jsonb_array_elements(public.get_my_notifications(30)) n
    where n ->> 'kind' = 'reply'
  ),
  'null'::jsonb,
  '通知に返信者名が含まれる(nameは未設定のためnull)'
);

select * from finish();
rollback;
