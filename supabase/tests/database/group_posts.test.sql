begin;
create extension if not exists pgtap;

select plan(7);

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

-- 非メンバーでも公開グループにはスレッドを作成できる
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000012', 'role', 'authenticated')::text,
  true
);
select lives_ok(
  format('select public.create_group_post(%L::uuid, %L)', :'gppub_id', 'こんにちは'),
  '非メンバーでも公開グループにはスレッドを作成できる'
);

-- 非メンバーは非公開グループには投稿できない
select throws_ok(
  format('select public.create_group_post(%L::uuid, %L)', :'gppriv_id', 'こんにちは'),
  '42501',
  'アクセス権がありません',
  '非メンバーは非公開グループに投稿できない'
);

-- オーナーがスレッドを作成し、そこに何度でもメッセージを送れる(LINEのグループトーク相当)
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000011', 'role', 'authenticated')::text,
  true
);
select (public.create_group_post(:'gppub_id'::uuid, 'スレッド開始')->>'id')::uuid as root_post_id \gset

select lives_ok(
  format('select public.create_group_post(%L::uuid, %L, %L::uuid)', :'gppub_id', '1通目', :'root_post_id'),
  'スレッドにメッセージを送れる'
);

select (public.create_group_post(:'gppub_id'::uuid, '2通目', :'root_post_id')->>'id')::uuid as msg2_id \gset

-- 「返信への返信」であっても、常にルートへ正規化されて登録される(禁止されない)
select lives_ok(
  format('select public.create_group_post(%L::uuid, %L, %L::uuid)', :'gppub_id', '3通目(2通目への返信のつもり)', :'msg2_id'),
  '既存メッセージへの返信も、実際にはスレッドのルートに正規化されて格納される'
);

select is(
  (
    select count(*) from jsonb_array_elements(public.get_thread_messages(:'root_post_id'::uuid))
  )::int,
  4,
  '正規化により、2通目宛の返信も含めスレッド内の全メッセージがルート配下として取得できる(ルート+3件)'
);

select is(
  (
    select count(*) from jsonb_array_elements(public.get_thread_messages(:'msg2_id'::uuid))
  )::int,
  4,
  'get_thread_messagesはルートでない(返信の)idを渡してもスレッド全体を解決できる'
);

-- get_group_postsはスレッド一覧(ルートのみ、件数付き)を返す
select is(
  (select count(*) from jsonb_array_elements(public.get_group_posts(:'gppub_id'::uuid)))::int,
  2,
  'get_group_postsはトップレベルのスレッドのみを返す'
);

select * from finish();
rollback;
