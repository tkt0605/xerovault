-- =====================================================================
-- 0001_init.sql 適用前に作成された auth.users には profiles 行が無いため、
-- 既存アカウント分を後追いで作成する（何度実行しても安全）。
-- =====================================================================

insert into public.profiles (id, email, name, avatar)
select
  u.id,
  u.email,
  coalesce(u.raw_user_meta_data ->> 'full_name', u.raw_user_meta_data ->> 'name'),
  coalesce(
    u.raw_user_meta_data ->> 'avatar_url',
    u.raw_user_meta_data ->> 'picture',
    public.default_avatar_url(u.email)
  )
from auth.users u
left join public.profiles p on p.id = u.id
where p.id is null;
