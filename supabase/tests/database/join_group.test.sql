begin;
create extension if not exists pgtap;

select plan(5);

-- テスト用ユーザー(handle_new_userトリガーでprofilesも自動作成される)
insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000001', 'jg-owner@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000002', 'jg-member@test.local', 'x', now(), 'authenticated', 'authenticated');

-- オーナーとして公開グループ・非公開グループを作成
set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text,
  true
);
select (public.create_group('jgpub', array[]::text[], true, null)->>'id')::uuid as jgpub_id \gset
select (public.create_group('jgpriv', array[]::text[], false, null)->>'id')::uuid as jgpriv_id \gset

-- 別ユーザーに切り替え
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text,
  true
);

select lives_ok(
  format('select public.join_group(%L::uuid, null)', :'jgpub_id'),
  '公開グループはトークンなしで参加できる'
);

select ok(
  exists (
    select 1 from jsonb_array_elements(public.get_group_detail(:'jgpub_id'::uuid) -> 'members') m
    where m ->> 'id' = '00000000-0000-0000-0000-000000000002'
  ),
  '参加後、membersに含まれる'
);

select throws_ok(
  format('select public.join_group(%L::uuid, null)', :'jgpub_id'),
  '23505',
  'すでに参加しています',
  'すでに参加済みの場合は再度参加できない'
);

select throws_ok(
  format('select public.join_group(%L::uuid, null)', :'jgpriv_id'),
  '22023',
  '無効なトークンです',
  '非公開グループはトークンなしで参加できない'
);

-- オーナーが公開グループから除名し、除名済みユーザーの再参加を拒否することを確認
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000001', 'role', 'authenticated')::text,
  true
);
select public.remove_member(:'jgpub_id'::uuid, '00000000-0000-0000-0000-000000000002');

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000002', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  format('select public.join_group(%L::uuid, null)', :'jgpub_id'),
  '42501',
  'このグループには参加できません',
  '除名されたユーザーは公開グループに再参加できない(0026_group_bansの回帰テスト)'
);

select * from finish();
rollback;
