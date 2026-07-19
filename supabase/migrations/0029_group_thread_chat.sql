-- =====================================================================
-- 掲示板を「投稿+1階層の返信」から「スレッド(LINEのグループトークに近い、
-- 何度でも会話を続けられる単位)」の形に変える。
--
-- データ構造は変えず(group_posts.parent_post_idのまま)、意味づけを変更する:
-- スレッド内の全メッセージは、常にスレッドの起点(ルート投稿)へ直接
-- ぶら下がる「フラットな1階層」として正規化する(メッセージ間のツリーは作らない)。
-- これにより「返信への返信は禁止」という制約は不要になる。
--
-- get_group_postsはスレッド一覧(ルート投稿+件数+最終メッセージ日時)のみを
-- 返すように変更し、個々のスレッドの中身は新設のget_thread_messagesで
-- 取得する。
-- =====================================================================

-- ---------------------------------------------------------------------
-- create_group_post: 返信は常にスレッドのルートへ正規化して格納する。
-- 新規メッセージが来たら、送信者以外のスレッド参加者全員に通知する。
-- ---------------------------------------------------------------------
create or replace function public.create_group_post(
  p_group_id uuid,
  p_text text,
  p_parent_post_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post public.group_posts;
  v_parent public.group_posts;
  v_root_id uuid;
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  if p_parent_post_id is not null then
    select * into v_parent from public.group_posts where id = p_parent_post_id;
    if v_parent.id is null or v_parent.group_id <> p_group_id then
      raise exception '投稿先のスレッドが見つかりません' using errcode = 'P0002';
    end if;
    -- 返信先が既に返信(ルートでない)なら、そのルートに正規化する
    v_root_id := coalesce(v_parent.parent_post_id, v_parent.id);
  end if;

  insert into public.group_posts (group_id, author_id, text, parent_post_id)
  values (p_group_id, auth.uid(), trim(p_text), v_root_id)
  returning * into v_post;

  if v_root_id is not null then
    insert into public.notification_log (user_id, kind, group_post_id)
    select distinct p.author_id, 'reply', v_post.id
    from public.group_posts p
    where (p.id = v_root_id or p.parent_post_id = v_root_id)
      and p.author_id <> auth.uid()
    on conflict (user_id, group_post_id) where kind = 'reply' do nothing;
  end if;

  return jsonb_build_object(
    'id', v_post.id,
    'text', v_post.text,
    'createdAt', v_post.created_at,
    'groupId', v_post.group_id,
    'authorId', v_post.author_id,
    'parentPostId', v_post.parent_post_id,
    'author', (select jsonb_build_object('id', id, 'email', email, 'name', name, 'avatar', avatar) from public.profiles where id = auth.uid())
  );
end;
$$;

grant execute on function public.create_group_post(uuid, text, uuid) to authenticated;

-- ---------------------------------------------------------------------
-- get_group_posts: スレッド一覧(ルート投稿+返信件数+最終メッセージ日時)
-- ---------------------------------------------------------------------
create or replace function public.get_group_posts(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(to_jsonb(t) order by t."lastMessageAt" desc)
    from (
      select
        p.id, p.text, p.created_at as "createdAt", p.group_id as "groupId", p.author_id as "authorId",
        jsonb_build_object('id', a.id, 'email', a.email, 'name', a.name, 'avatar', a.avatar) as author,
        (select count(*) from public.group_posts r where r.parent_post_id = p.id)::int as "replyCount",
        greatest(
          p.created_at,
          coalesce((select max(r.created_at) from public.group_posts r where r.parent_post_id = p.id), p.created_at)
        ) as "lastMessageAt"
      from public.group_posts p
      join public.profiles a on a.id = p.author_id
      where p.group_id = p_group_id and p.parent_post_id is null
    ) t
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_group_posts(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- get_thread_messages: スレッド内の全メッセージ(ルート含む)を時系列で返す
-- ---------------------------------------------------------------------
create or replace function public.get_thread_messages(p_post_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_post public.group_posts;
  v_root_id uuid;
begin
  select * into v_post from public.group_posts where id = p_post_id;
  if v_post.id is null then
    raise exception 'スレッドが見つかりません' using errcode = 'P0002';
  end if;
  -- 渡されたidがルートでも返信でも、常にスレッドのルートを解決する
  v_root_id := coalesce(v_post.parent_post_id, v_post.id);

  if not (
    public.is_group_member(v_post.group_id)
    or exists (select 1 from public.groups where id = v_post.group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(to_jsonb(t) order by t."createdAt" asc)
    from (
      select
        p.id, p.text, p.created_at as "createdAt", p.group_id as "groupId", p.author_id as "authorId",
        jsonb_build_object('id', a.id, 'email', a.email, 'name', a.name, 'avatar', a.avatar) as author
      from public.group_posts p
      join public.profiles a on a.id = p.author_id
      where p.id = v_root_id or p.parent_post_id = v_root_id
    ) t
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_thread_messages(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- スレッド内の新規メッセージをRealtimeで購読できるようにする
-- ---------------------------------------------------------------------
alter publication supabase_realtime add table public.group_posts;
