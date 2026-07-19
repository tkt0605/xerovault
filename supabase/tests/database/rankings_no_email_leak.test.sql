-- 回帰テスト: get_rankingsが未ログインユーザー(anon)にオーナーのemailを
-- 返してしまっていたセキュリティ修正(0025_rankings_owner_email_leak_fix.sql)。
begin;
create extension if not exists pgtap;

select plan(2);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values ('00000000-0000-0000-0000-000000000031', 'rk-owner@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000031', 'role', 'authenticated')::text,
  true
);
select public.create_group('rkpub', array[]::text[], true, null);

-- 未ログイン(anon)としてget_rankingsを呼ぶ
reset role;
set local role anon;

select ok(
  exists (
    select 1 from jsonb_array_elements(public.get_rankings(20, null)) g
    where g -> 'owner' ->> 'id' = '00000000-0000-0000-0000-000000000031'
  ),
  'anonでもget_rankingsで公開グループを取得できる'
);

select ok(
  not exists (
    select 1 from jsonb_array_elements(public.get_rankings(20, null)) g
    where (g -> 'owner') ? 'email'
  ),
  'get_rankingsのownerにemailキーが含まれない(anonへのemail漏洩防止)'
);

select * from finish();
rollback;
