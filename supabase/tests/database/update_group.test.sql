begin;
create extension if not exists pgtap;

select plan(3);

insert into auth.users (id, email, encrypted_password, email_confirmed_at, aud, role)
values
  ('00000000-0000-0000-0000-000000000021', 'ug-owner@test.local', 'x', now(), 'authenticated', 'authenticated'),
  ('00000000-0000-0000-0000-000000000022', 'ug-outsider@test.local', 'x', now(), 'authenticated', 'authenticated');

set local role authenticated;
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000021', 'role', 'authenticated')::text,
  true
);
select (public.create_group('uggroup', array[]::text[], true, '元の説明')->>'id')::uuid as ug_id \gset

select lives_ok(
  format('select public.update_group(%L::uuid, null, null, %L)', :'ug_id', '新しい説明'),
  'オーナーはグループを編集できる'
);

select is(
  public.get_group_detail(:'ug_id'::uuid) ->> 'description',
  '新しい説明',
  '編集内容が反映される'
);

-- オーナー以外は編集できない
select set_config(
  'request.jwt.claims',
  json_build_object('sub', '00000000-0000-0000-0000-000000000022', 'role', 'authenticated')::text,
  true
);
select throws_ok(
  format('select public.update_group(%L::uuid, null, null, %L)', :'ug_id', '乗っ取り'),
  '42501',
  'オーナーのみ編集できます',
  'オーナー以外はグループを編集できない'
);

select * from finish();
rollback;
