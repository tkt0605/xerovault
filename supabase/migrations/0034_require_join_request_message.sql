-- =====================================================================
-- 招待制申請の「志望動機」を必須化する。
--
-- group_join_requests.message列自体は既存の承認/却下済みレコードに
-- nullが残っているためNOT NULL化はせず、create_join_request RPC側で
-- 空/空白のみのメッセージを拒否するガードを追加する。
-- =====================================================================

create or replace function public.create_join_request(p_group_id uuid, p_message text default null)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group public.groups;
  v_request public.group_join_requests;
  v_message text;
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

  if exists (select 1 from public.group_join_requests where group_id = p_group_id and user_id = auth.uid()) then
    raise exception 'すでに参加をリクエスト済みです' using errcode = '23505';
  end if;

  v_message := nullif(trim(p_message), '');
  if v_message is null then
    raise exception '志望動機を入力してください' using errcode = '22004';
  end if;

  insert into public.group_join_requests (group_id, user_id, message)
  values (p_group_id, auth.uid(), v_message)
  returning * into v_request;

  insert into public.notification_log (user_id, kind, group_join_request_id)
  values (v_group.owner_id, 'join_request', v_request.id);

  return jsonb_build_object(
    'id', v_request.id,
    'groupId', v_request.group_id,
    'status', v_request.status,
    'createdAt', v_request.created_at
  );
end;
$$;
