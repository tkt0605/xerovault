-- 回帰テスト: get_my_notificationsのreply通知のpostIdは、返信メッセージ
-- 自身のidではなく、常にスレッドのルートidを指す(0030での修正)。
-- フロントはこのpostIdをそのままスレッドページのURLに使うため、
-- ここがルートidでないとRealtime購読やメッセージ送信先がずれる。
begin;
create extension if not exists pgtap;

select plan(1);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000061', 'rp-author@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000062', 'rp-replier@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000061', 'role', 'authenticated')::text,
  true
);
select (public.create_group('rpgroup', array[]::text[], true, null)->>'id')::uuid as rp_group_id \gset
select (public.create_group_post(:'rp_group_id'::uuid, 'ルート投稿')->>'id')::uuid as rp_root_id \gset

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000062', 'role', 'authenticated')::text,
  true
);
select public.create_group_post(:'rp_group_id'::uuid, '返信', :'rp_root_id');

select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000061', 'role', 'authenticated')::text,
  true
);

select is(
  (
    select n ->> 'postId' from jsonb_array_elements(public.get_my_notifications(30)) n
    where n ->> 'kind' = 'reply'
  )::uuid,
  :'rp_root_id'::uuid,
  '通知のpostIdは返信メッセージ自身ではなくスレッドのルートidを指す'
);

select * from finish();
rollback;
