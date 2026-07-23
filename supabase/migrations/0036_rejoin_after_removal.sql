-- =====================================================================
-- 除名(remove_member)されたメンバーが「参加リクエストURL」から再申請しても、
-- group_join_requestsの古いapproved行が(group_id, user_id)の永久ユニーク制約に
-- 引っかかり、「参加が承認されています」という嘘の表示のまま実際のメンバー
-- 状態とズレ続けるバグを修正する。
--
-- 根本原因: group_join_requestsは「グループ×ユーザーにつき1行だけ、しかも
-- 一度decided_atがついたら二度と新しい申請ができない」設計になっていた。
-- 「同時に有効なpending申請は1件まで」という制約に緩め、解決済み(approved/
-- rejected)の履歴行は複数残せるようにする。
-- =====================================================================

alter table public.group_join_requests
  drop constraint group_join_requests_group_id_user_id_key;

create unique index group_join_requests_pending_unique
  on public.group_join_requests (group_id, user_id)
  where status = 'pending';

-- ---------------------------------------------------------------------
-- create_join_request: 「既に申請済み」チェックをpending行のみに限定する。
-- 解決済みの古い行があっても新規insertできるようにする(unique制約もpending
-- のみになったため、単純なinsertのままでよい)
-- ---------------------------------------------------------------------
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

  if exists (
    select 1 from public.group_join_requests
    where group_id = p_group_id and user_id = auth.uid() and status = 'pending'
  ) then
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

grant execute on function public.create_join_request(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- get_group_join_request_target: 現在の実メンバーシップを優先して見る。
-- 「approved」は現在メンバーであることで裏取りする(除名後は嘘のapproved
-- を返さない)。「rejected」は履歴としてそのままフィードバックする(除名とは
-- 無関係に、直近の申請が却下されたという事実は変わらないため)。
-- ---------------------------------------------------------------------
create or replace function public.get_group_join_request_target(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_group public.groups;
  v_status text;
begin
  select * into v_group from public.groups where id = p_group_id;
  if v_group.id is null then
    raise exception 'グループが見つかりません' using errcode = 'P0002';
  end if;

  if exists (select 1 from public.group_members where group_id = p_group_id and user_id = auth.uid()) then
    v_status := 'approved';
  else
    select status into v_status
    from public.group_join_requests
    where group_id = p_group_id and user_id = auth.uid()
    order by created_at desc
    limit 1;

    -- 過去にapprovedされた申請でも、現在メンバーでないなら除名済みなどで
    -- 実態とズレている。嘘のapprovedを返さず、再申請できるようnullに戻す
    if v_status = 'approved' then
      v_status := null;
    end if;
  end if;

  return jsonb_build_object(
    'id', v_group.id,
    'name', v_group.name,
    'description', v_group.description,
    'tags', v_group.tags,
    'myRequestStatus', v_status
  );
end;
$$;

grant execute on function public.get_group_join_request_target(uuid) to authenticated;
