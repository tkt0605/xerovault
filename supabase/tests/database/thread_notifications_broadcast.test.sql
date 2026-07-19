-- スレッドは「LINEのグループトーク」のように複数人が会話に参加する前提のため、
-- 新規メッセージは送信者以外の"それまでの参加者全員"に通知される必要がある。
begin;
create extension if not exists pgtap;

select plan(2);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000051', 'tb-a@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000052', 'tb-b@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000053', 'tb-c@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;

-- Aがスレッドを開始
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000051', 'role', 'authenticated')::text,
  true
);
select (public.create_group('tbgroup', array[]::text[], true, null)->>'id')::uuid as tb_group_id \gset
select (public.create_group_post(:'tb_group_id'::uuid, 'スレッド開始')->>'id')::uuid as tb_root_id \gset

-- Bが参加してメッセージを送る(この時点でAに通知される)
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000052', 'role', 'authenticated')::text,
  true
);
select public.create_group_post(:'tb_group_id'::uuid, 'Bです', :'tb_root_id');

-- Cが参加してメッセージを送る(この時点でA・Bの両方に通知される必要がある)
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000053', 'role', 'authenticated')::text,
  true
);
select public.create_group_post(:'tb_group_id'::uuid, 'Cです', :'tb_root_id');

-- Aの通知を確認(Bの発言・Cの発言の両方で通知が届いているはず)
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000051', 'role', 'authenticated')::text,
  true
);
select is(
  (select count(*) from jsonb_array_elements(public.get_my_notifications(30)) n where n ->> 'kind' = 'reply')::int,
  2,
  'スレッド開始者には後続の全メッセージ(B・C)の通知が届く'
);

-- Bの通知を確認(Cの発言だけ通知が届く。Bが送った自分の発言は通知されない)
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000052', 'role', 'authenticated')::text,
  true
);
select is(
  (select count(*) from jsonb_array_elements(public.get_my_notifications(30)) n where n ->> 'kind' = 'reply')::int,
  1,
  '途中参加者にも、参加後の新規メッセージ(C)の通知が届く'
);

select * from finish();
rollback;
