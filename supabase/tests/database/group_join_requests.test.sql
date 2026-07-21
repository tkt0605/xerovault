begin;
create extension if not exists pgtap;

select plan(11);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000021', 'gjr-owner@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000022', 'gjr-applicant1@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000023', 'gjr-applicant2@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text,
  true
);
select (public.create_group('gjrpriv', array[]::text[], false, null)->>'id')::uuid as gjr_id \gset

-- applicant1が申請する
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000022', 'role', 'authenticated')::text,
  true
);
select lives_ok(
  format('select public.create_join_request(%L::uuid, %L)', :'gjr_id', 'よろしくお願いします'),
  '未参加ユーザーは参加をリクエストできる'
);

select throws_ok(
  format('select public.create_join_request(%L::uuid, %L)', :'gjr_id', 'もう一度'),
  '23505',
  'すでに参加をリクエスト済みです',
  '同じグループに二重で申請できない'
);

-- applicant2(オーナーではない)は申請一覧を見られない
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000023', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  format('select public.get_group_join_requests(%L::uuid)', :'gjr_id'),
  '42501',
  'オーナーのみ閲覧できます',
  'オーナー以外は申請一覧を閲覧できない'
);

-- オーナーは申請一覧(pendingのみ)を閲覧できる
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text,
  true
);
select is(
  (public.get_group_join_requests(:'gjr_id'::uuid) -> 0 ->> 'message'),
  'よろしくお願いします',
  'オーナーは申請メッセージ付きで一覧を取得できる'
);

select (public.get_group_join_requests(:'gjr_id'::uuid) -> 0 ->> 'id')::uuid as req1_id \gset

-- applicant2はオーナーではないので承認できない
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000023', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  format('select public.approve_join_request(%L::uuid)', :'req1_id'),
  '42501',
  'オーナーのみ承認できます',
  'オーナー以外は申請を承認できない'
);

-- オーナーが承認する
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text,
  true
);
select lives_ok(
  format('select public.approve_join_request(%L::uuid)', :'req1_id'),
  'オーナーは申請を承認できる'
);

select ok(
  exists (
    select 1 from jsonb_array_elements(public.get_group_detail(:'gjr_id'::uuid) -> 'members') m
    where m ->> 'id' = '00000000-0000-0000-0000-000000000022'
  ),
  '承認後、申請者はメンバーに含まれる'
);

select throws_ok(
  format('select public.approve_join_request(%L::uuid)', :'req1_id'),
  '22023',
  'この申請は既に処理済みです',
  '処理済みの申請は再度承認できない'
);

-- applicant2が申請し、オーナーが却下する。却下後は再申請できない
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000023', 'role', 'authenticated')::text,
  true
);
select public.create_join_request(:'gjr_id'::uuid, null);

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text,
  true
);
select (public.get_group_join_requests(:'gjr_id'::uuid) -> 0 ->> 'id')::uuid as req2_id \gset

select lives_ok(
  format('select public.reject_join_request(%L::uuid)', :'req2_id'),
  'オーナーは申請を却下できる'
);

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000023', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  format('select public.create_join_request(%L::uuid, null)', :'gjr_id'),
  '23505',
  'すでに参加をリクエスト済みです',
  '却下された申請は同じグループへ再申請できない'
);

-- オーナーが承認済みメンバーを除名(BAN)すると、除名済みユーザーは再申請できない
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text,
  true
);
select public.remove_member(:'gjr_id'::uuid, '00000000-0000-0000-0000-000000000022');

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000022', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  format('select public.create_join_request(%L::uuid, null)', :'gjr_id'),
  '42501',
  'このグループには参加できません',
  '除名済みユーザーは参加をリクエストできない'
);

select * from finish();
rollback;
