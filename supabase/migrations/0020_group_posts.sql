-- =====================================================================
-- 「参加前に会話できる場」が無い問題への対応。
-- グループページに、参加前でも(公開グループなら非メンバーでも)投稿できる
-- Twitter風の「ようこそ掲示板」を追加する。
-- 書き込みは messages/send_message と同じくRPC経由のみに絞り、
-- テーブルにはINSERT用のRLSポリシーを作らない。
-- =====================================================================

create table public.group_posts (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  text text not null check (char_length(trim(text)) between 1 and 280),
  created_at timestamptz not null default now()
);

create index idx_group_posts_group_id on public.group_posts (group_id);

alter table public.group_posts enable row level security;

create policy "group_posts visible to members or public groups"
  on public.group_posts for select
  to authenticated
  using (
    public.is_group_member(group_id)
    or exists (select 1 from public.groups where id = group_id and is_public)
  );

-- ---------------------------------------------------------------------
-- get_group_posts / create_group_post
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
        jsonb_build_object('id', a.id, 'email', a.email, 'name', a.name, 'avatar', a.avatar) as author
      from public.group_posts p
      join public.profiles a on a.id = p.author_id
      where p.group_id = p_group_id
    ) t
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_group_posts(uuid) to authenticated;

create or replace function public.create_group_post(p_group_id uuid, p_text text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_post public.group_posts;
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  insert into public.group_posts (group_id, author_id, text)
  values (p_group_id, auth.uid(), trim(p_text))
  returning * into v_post;

  return jsonb_build_object(
    'id', v_post.id,
    'text', v_post.text,
    'createdAt', v_post.created_at,
    'groupId', v_post.group_id,
    'authorId', v_post.author_id,
    'author', (select jsonb_build_object('id', id, 'email', email, 'name', name, 'avatar', avatar) from public.profiles where id = auth.uid())
  );
end;
$$;

grant execute on function public.create_group_post(uuid, text) to authenticated;

-- ---------------------------------------------------------------------
-- group_last_activity_at / group_member_activity: 掲示板投稿も活動として算入
-- ---------------------------------------------------------------------
create or replace function public.group_last_activity_at(p_group_id uuid)
returns timestamptz
language sql
security definer
stable
set search_path = public
as $$
  select greatest(
    (select g.created_at from public.groups g where g.id = p_group_id),
    coalesce((select max(g.created_at) from public.goals g where g.group_id = p_group_id), '-infinity'::timestamptz),
    coalesce(
      (select max(v.created_at)
       from public.votes v
       join public.goals g on g.id = v.goal_id
       where g.group_id = p_group_id),
      '-infinity'::timestamptz
    ),
    coalesce(
      (select max(m.created_at)
       from public.messages m
       join public.goals g on g.id = m.goal_id
       where g.group_id = p_group_id),
      '-infinity'::timestamptz
    ),
    coalesce(
      (select max(p.created_at) from public.group_posts p where p.group_id = p_group_id),
      '-infinity'::timestamptz
    )
  );
$$;

create or replace function public.group_member_activity(p_group_id uuid, p_user_id uuid)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select jsonb_build_object(
    'completedGoalsCount', (
      select count(*) from public.goals
      where group_id = p_group_id and assignee_id = p_user_id and is_completed = true
    ),
    'lastActiveAt', nullif(greatest(
      coalesce(
        (select max(g.updated_at) from public.goals g where g.group_id = p_group_id and g.assignee_id = p_user_id),
        '-infinity'::timestamptz
      ),
      coalesce(
        (select max(m.created_at)
         from public.messages m
         join public.goals g on g.id = m.goal_id
         where g.group_id = p_group_id and m.author_id = p_user_id),
        '-infinity'::timestamptz
      ),
      coalesce(
        (select max(v.created_at)
         from public.votes v
         join public.goals g on g.id = v.goal_id
         where g.group_id = p_group_id and v.voter_id = p_user_id),
        '-infinity'::timestamptz
      ),
      coalesce(
        (select max(p.created_at) from public.group_posts p where p.group_id = p_group_id and p.author_id = p_user_id),
        '-infinity'::timestamptz
      )
    ), '-infinity'::timestamptz)
  );
$$;
