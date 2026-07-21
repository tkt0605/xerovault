-- =====================================================================
-- クローズドβ移行に伴い、公開グループのトークンなし自己参加(0017)を閉じる。
-- 招待は「オーナーの直接トークンリンク」か「0032の申請制ウェイトリスト」の
-- いずれかを経由する形に統一する。
-- =====================================================================

create or replace function public.join_group(p_group_id uuid, p_token text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group public.groups;
begin
  select * into v_group from public.groups where id = p_group_id;
  if v_group.id is null then
    raise exception 'グループが存在しません' using errcode = 'P0002';
  end if;

  if exists (select 1 from public.group_members where group_id = p_group_id and user_id = auth.uid()) then
    raise exception 'すでに参加しています' using errcode = '23505';
  end if;

  if exists (select 1 from public.group_bans where group_id = p_group_id and user_id = auth.uid()) then
    raise exception 'このグループには参加できません' using errcode = '42501';
  end if;

  if p_token is null or v_group.join_token is null or v_group.join_token <> p_token then
    raise exception '無効なトークンです' using errcode = '22023';
  end if;
  if v_group.join_token_expires_at is null or v_group.join_token_expires_at < now() then
    raise exception '招待リンクの有効期限が切れています' using errcode = '22023';
  end if;

  insert into public.group_members (group_id, user_id) values (p_group_id, auth.uid());

  return public.get_group_detail(p_group_id);
end;
$$;

grant execute on function public.join_group(uuid, text) to authenticated;
