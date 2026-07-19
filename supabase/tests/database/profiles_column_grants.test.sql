-- 回帰テスト: profiles.SELECTは列単位ホワイトリスト制(0010)。
-- bio(0018)/interest_tags(0019)追加時にホワイトリスト反映が漏れ、
-- クライアントからの直接selectが失敗していた不具合の修正(0024)。
-- 併せてunsubscribe_tokenのような非公開列が引き続き閉じていることも確認する。
begin;
create extension if not exists pgtap;

select plan(3);

select ok(
  has_column_privilege('authenticated', 'public.profiles', 'bio', 'select'),
  'authenticatedはprofiles.bioをSELECTできる'
);

select ok(
  has_column_privilege('authenticated', 'public.profiles', 'interest_tags', 'select'),
  'authenticatedはprofiles.interest_tagsをSELECTできる'
);

select ok(
  not has_column_privilege('authenticated', 'public.profiles', 'unsubscribe_token', 'select'),
  'authenticatedはprofiles.unsubscribe_tokenをSELECTできない(公開してはいけない列)'
);

select * from finish();
rollback;
