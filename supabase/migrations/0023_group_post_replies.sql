-- =====================================================================
-- 大きい公開グループに飛び込むハードルを下げるため、既存の「ようこそ掲示板」
-- (group_posts) の投稿に返信(1階層のスレッド)を追加する。
-- 返信への返信は許可しない(シンプルさ優先)。
-- =====================================================================

alter table public.group_posts add column parent_post_id uuid references public.group_posts (id) on delete cascade;

create index idx_group_posts_parent_post_id on public.group_posts (parent_post_id);

-- ---------------------------------------------------------------------
-- get_group_posts: トップレベル投稿ごとにrepliesを埋め込む
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
    select jsonb_agg(to_jsonb(t) order by t."createdAt" desc)
    from (
      select
        p.id, p.text, p.created_at as "createdAt", p.group_id as "groupId", p.author_id as "authorId",
        p.parent_post_id as "parentPostId",
        jsonb_build_object('id', a.id, 'email', a.email, 'name', a.name, 'avatar', a.avatar) as author,
        coalesce((
          select jsonb_agg(
            jsonb_build_object(
              'id', r.id, 'text', r.text, 'createdAt', r.created_at, 'groupId', r.group_id,
              'authorId', r.author_id, 'parentPostId', r.parent_post_id,
              'author', jsonb_build_object('id', ra.id, 'email', ra.email, 'name', ra.name, 'avatar', ra.avatar),
              'replies', '[]'::jsonb
            ) order by r.created_at asc
          )
          from public.group_posts r
          join public.profiles ra on ra.id = r.author_id
          where r.parent_post_id = p.id
        ), '[]'::jsonb) as replies
      from public.group_posts p
      join public.profiles a on a.id = p.author_id
      where p.group_id = p_group_id and p.parent_post_id is null
    ) t
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_group_posts(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- create_group_post: p_parent_post_id を追加(1階層制限)
-- ---------------------------------------------------------------------
drop function if exists public.create_group_post(uuid, text);

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
      raise exception '返信先の投稿が見つかりません' using errcode = 'P0002';
    end if;
    if v_parent.parent_post_id is not null then
      raise exception '返信への返信はできません' using errcode = '22023';
    end if;
  end if;

  insert into public.group_posts (group_id, author_id, text, parent_post_id)
  values (p_group_id, auth.uid(), trim(p_text), p_parent_post_id)
  returning * into v_post;

  return jsonb_build_object(
    'id', v_post.id,
    'text', v_post.text,
    'createdAt', v_post.created_at,
    'groupId', v_post.group_id,
    'authorId', v_post.author_id,
    'parentPostId', v_post.parent_post_id,
    'author', (select jsonb_build_object('id', id, 'email', email, 'name', name, 'avatar', avatar) from public.profiles where id = auth.uid()),
    'replies', '[]'::jsonb
  );
end;
$$;

grant execute on function public.create_group_post(uuid, text, uuid) to authenticated;
