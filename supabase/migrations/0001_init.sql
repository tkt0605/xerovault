-- =====================================================================
-- Xerovault: Supabase schema / RLS / RPC functions (Express+Prisma代替)
-- Supabaseダッシュボード > SQL Editor に全文貼り付けて実行してください。
-- =====================================================================

create extension if not exists pgcrypto;

-- =====================================================================
-- profiles（auth.usersとの同期）
-- =====================================================================

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text unique not null,
  name text,
  avatar text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles are viewable by authenticated users"
  on public.profiles for select
  to authenticated
  using (true);

create policy "users can update own profile"
  on public.profiles for update
  to authenticated
  using (id = auth.uid())
  with check (id = auth.uid());

create or replace function public.default_avatar_url(p_email text)
returns text
language sql
immutable
as $$
  select 'https://api.dicebear.com/9.x/identicon/svg?seed=' || split_part(p_email, '@', 1);
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, avatar)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture',
      public.default_avatar_url(new.email)
    )
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =====================================================================
-- groups / group_members
-- =====================================================================

create table public.groups (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  tag text,
  is_public boolean not null default false,
  join_token text,
  join_token_expires_at timestamptz,
  score integer not null default 100,
  streak integer not null default 0,
  owner_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.group_members (
  group_id uuid not null references public.groups (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (group_id, user_id)
);

create index idx_group_members_user_id on public.group_members (user_id);

-- グループ所属判定ヘルパー（オーナー or メンバー）。RLSポリシー・各RPCから共通で使う
create or replace function public.is_group_member(p_group_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.groups g where g.id = p_group_id and g.owner_id = auth.uid()
  ) or exists (
    select 1 from public.group_members gm where gm.group_id = p_group_id and gm.user_id = auth.uid()
  );
$$;

alter table public.groups enable row level security;
alter table public.group_members enable row level security;

-- 書き込みはすべてSECURITY DEFINERなRPC経由に限定するため、直接のinsert/update/deleteポリシーは用意しない
create policy "groups visible to members or if public"
  on public.groups for select
  to authenticated
  using (is_public or public.is_group_member(id));

create policy "group_members visible to members"
  on public.group_members for select
  to authenticated
  using (public.is_group_member(group_id));

-- =====================================================================
-- goals
-- =====================================================================

create table public.goals (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.groups (id) on delete cascade,
  header text,
  description text not null,
  deadline timestamptz,
  assignee_id uuid references public.profiles (id) on delete set null,
  is_concrete boolean generated always as (deadline is not null and assignee_id is not null) stored,
  is_completed boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_goals_group_id on public.goals (group_id);

alter table public.goals enable row level security;

create policy "goals visible to group members"
  on public.goals for select
  to authenticated
  using (public.is_group_member(group_id));

-- =====================================================================
-- goal_votes（投票席） / votes（実際のYES/NO値）
-- 取り消し時は votes だけ削除し goal_votes は残す、という既存の意味論を踏襲
-- =====================================================================

create table public.goal_votes (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals (id) on delete cascade,
  voter_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (goal_id, voter_id)
);

create index idx_goal_votes_goal_id on public.goal_votes (goal_id);

create table public.votes (
  id uuid primary key default gen_random_uuid(),
  goal_vote_id uuid not null unique references public.goal_votes (id) on delete cascade,
  goal_id uuid not null references public.goals (id) on delete cascade, -- 非正規化（Realtimeのfilter用）
  voter_id uuid not null references public.profiles (id) on delete cascade,
  is_yes boolean not null,
  created_at timestamptz not null default now()
);

create index idx_votes_goal_id on public.votes (goal_id);

alter table public.goal_votes enable row level security;
alter table public.votes enable row level security;

create policy "goal_votes visible to group members"
  on public.goal_votes for select
  to authenticated
  using (public.is_group_member((select g.group_id from public.goals g where g.id = goal_votes.goal_id)));

create policy "votes visible to group members"
  on public.votes for select
  to authenticated
  using (public.is_group_member((select g.group_id from public.goals g where g.id = votes.goal_id)));

-- =====================================================================
-- messages
-- =====================================================================

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  text text not null,
  created_at timestamptz not null default now()
);

create index idx_messages_goal_id on public.messages (goal_id);

alter table public.messages enable row level security;

create policy "messages visible to group members"
  on public.messages for select
  to authenticated
  using (public.is_group_member((select g.group_id from public.goals g where g.id = messages.goal_id)));

-- Realtimeで変更を配信できるようにpublicationへ追加
alter publication supabase_realtime add table public.votes;
alter publication supabase_realtime add table public.messages;

-- =====================================================================
-- スコア計算ヘルパー（backend/src/services/scoreService.ts の定数・ロジックを移植）
-- =====================================================================

create or replace function public.calc_vote_progress(p_goal_id uuid)
returns integer
language sql
security definer
stable
set search_path = public
as $$
  select case when member_count = 0 then 0
    else round((yes_count::numeric / member_count) * 100)::integer
  end
  from (
    select
      (select count(*) from public.group_members gm where gm.group_id = g.group_id) as member_count,
      (select count(*) from public.votes v where v.goal_id = g.id and v.is_yes = true) as yes_count
    from public.goals g where g.id = p_goal_id
  ) s;
$$;

grant execute on function public.calc_vote_progress(uuid) to authenticated;

create or replace function public.calc_goal_status(p_is_completed boolean, p_deadline timestamptz, p_assignee_id uuid)
returns text
language sql
immutable
as $$
  select case
    when p_is_completed then 'completed'
    when p_deadline is not null and p_assignee_id is not null and p_deadline < now() then 'missed'
    else 'pending'
  end;
$$;

-- グループのscore/streakをフル再計算する（votesの変更のたびに毎回呼ぶ。missed遅延評価はこの呼び出しタイミングでのみ反映される既存の制約を踏襲）
create or replace function public.recalc_group_score(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total_members integer;
  v_score integer;
  v_streak integer := 0;
  v_missed_count integer;
  v_trailing boolean := true;
  rec record;
begin
  select count(*) into v_total_members from public.group_members where group_id = p_group_id;

  select 100 + coalesce(sum(
    round(
      (case when g.is_concrete then 25 else 5 end) *
      (case when v_total_members > 0 and (
        (select count(distinct gv.voter_id)
         from public.goal_votes gv
         join public.votes v on v.goal_vote_id = gv.id
         where gv.goal_id = g.id)::numeric / v_total_members
      ) >= 1.0 then 1.5 else 1.0 end)
    )
  ), 0)::integer
  into v_score
  from public.goals g
  where g.group_id = p_group_id and g.is_completed = true;

  select count(*) into v_missed_count
  from public.goals g
  where g.group_id = p_group_id
    and g.is_concrete
    and g.is_completed = false
    and g.deadline < now();

  v_score := v_score - v_missed_count * 25;

  for rec in
    select is_completed
    from public.goals
    where group_id = p_group_id
      and is_concrete
      and (is_completed = true or deadline < now())
    order by deadline desc
  loop
    if v_trailing and rec.is_completed then
      v_streak := v_streak + 1;
    else
      v_trailing := false;
    end if;
  end loop;

  if v_streak >= 3 then
    v_score := v_score + 50;
  end if;

  v_score := greatest(0, least(v_score, 9999));

  update public.groups set score = v_score, streak = v_streak, updated_at = now() where id = p_group_id;
end;
$$;

-- =====================================================================
-- RPC: groups
-- =====================================================================

create or replace function public.get_group_detail(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_result jsonb;
begin
  if not (
    public.is_group_member(p_group_id)
    or exists (select 1 from public.groups where id = p_group_id and is_public)
  ) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'id', g.id,
    'name', g.name,
    'tag', g.tag,
    'isPublic', g.is_public,
    'score', g.score,
    'streak', g.streak,
    'joinToken', g.join_token,
    'createdAt', g.created_at,
    'updatedAt', g.updated_at,
    'owner', jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar),
    'members', (
      select coalesce(jsonb_agg(jsonb_build_object('id', mp.id, 'email', mp.email, 'name', mp.name, 'avatar', mp.avatar)), '[]'::jsonb)
      from public.group_members gm
      join public.profiles mp on mp.id = gm.user_id
      where gm.group_id = g.id
    ),
    '_count', jsonb_build_object('goals', (select count(*) from public.goals where group_id = g.id))
  )
  into v_result
  from public.groups g
  join public.profiles o on o.id = g.owner_id
  where g.id = p_group_id;

  if v_result is null then
    raise exception 'グループが存在しません' using errcode = 'P0002';
  end if;

  return v_result;
end;
$$;

grant execute on function public.get_group_detail(uuid) to authenticated;

create or replace function public.get_my_groups()
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t) order by t."updatedAt" desc), '[]'::jsonb)
  from (
    select
      g.id,
      g.name,
      g.tag,
      g.is_public as "isPublic",
      g.score,
      g.streak,
      g.join_token as "joinToken",
      g.created_at as "createdAt",
      g.updated_at as "updatedAt",
      jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar) as owner,
      (
        select coalesce(jsonb_agg(jsonb_build_object('id', mp.id, 'email', mp.email, 'name', mp.name, 'avatar', mp.avatar)), '[]'::jsonb)
        from public.group_members gm2
        join public.profiles mp on mp.id = gm2.user_id
        where gm2.group_id = g.id
      ) as members,
      jsonb_build_object('goals', (select count(*) from public.goals gl where gl.group_id = g.id)) as "_count"
    from public.groups g
    join public.profiles o on o.id = g.owner_id
    where g.owner_id = auth.uid()
       or exists (select 1 from public.group_members gm where gm.group_id = g.id and gm.user_id = auth.uid())
  ) t;
$$;

grant execute on function public.get_my_groups() to authenticated;

create or replace function public.create_group(p_name text, p_tag text default null, p_is_public boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  insert into public.groups (name, tag, is_public, owner_id)
  values (p_name, p_tag, coalesce(p_is_public, false), auth.uid())
  returning id into v_group_id;

  insert into public.group_members (group_id, user_id) values (v_group_id, auth.uid());

  return public.get_group_detail(v_group_id);
end;
$$;

grant execute on function public.create_group(text, text, boolean) to authenticated;

create or replace function public.create_invite(p_group_id uuid, p_expire_in integer default 3600)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_token text;
begin
  if not exists (select 1 from public.groups where id = p_group_id and owner_id = auth.uid()) then
    raise exception '招待権限がありません' using errcode = '42501';
  end if;

  v_token := encode(gen_random_bytes(16), 'hex');

  update public.groups
  set join_token = v_token,
      join_token_expires_at = now() + make_interval(secs => p_expire_in)
  where id = p_group_id;

  return v_token;
end;
$$;

grant execute on function public.create_invite(uuid, integer) to authenticated;

create or replace function public.join_group(p_group_id uuid, p_token text)
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
  if v_group.join_token is null or v_group.join_token <> p_token then
    raise exception '無効なトークンです' using errcode = '22023';
  end if;
  if v_group.join_token_expires_at is null or v_group.join_token_expires_at < now() then
    raise exception '招待リンクの有効期限が切れています' using errcode = '22023';
  end if;
  if exists (select 1 from public.group_members where group_id = p_group_id and user_id = auth.uid()) then
    raise exception 'すでに参加しています' using errcode = '23505';
  end if;

  insert into public.group_members (group_id, user_id) values (p_group_id, auth.uid());

  return public.get_group_detail(p_group_id);
end;
$$;

grant execute on function public.join_group(uuid, text) to authenticated;

create or replace function public.remove_member(p_group_id uuid, p_member_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_id uuid;
begin
  select owner_id into v_owner_id from public.groups where id = p_group_id;
  if v_owner_id is null then
    raise exception 'グループが存在しません' using errcode = 'P0002';
  end if;
  if v_owner_id <> auth.uid() then
    raise exception '除名権限がありません' using errcode = '42501';
  end if;
  if p_member_id = v_owner_id then
    raise exception 'オーナーを除名できません' using errcode = '22023';
  end if;

  delete from public.group_members where group_id = p_group_id and user_id = p_member_id;
end;
$$;

grant execute on function public.remove_member(uuid, uuid) to authenticated;

-- =====================================================================
-- RPC: goals
-- =====================================================================

create or replace function public.get_goals(p_group_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if not public.is_group_member(p_group_id) then
    raise exception 'グループのメンバーではありません' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(to_jsonb(t) order by t."createdAt" desc)
    from (
      select
        g.id,
        g.header,
        g.description,
        g.deadline,
        g.is_concrete as "isConcrete",
        g.is_completed as "isCompleted",
        public.calc_goal_status(g.is_completed, g.deadline, g.assignee_id) as status,
        g.created_at as "createdAt",
        g.updated_at as "updatedAt",
        g.group_id as "groupId",
        g.assignee_id as "assigneeId",
        case when a.id is null then null
          else jsonb_build_object('id', a.id, 'email', a.email, 'name', a.name, 'avatar', a.avatar)
        end as assignee,
        public.calc_vote_progress(g.id) as progress
      from public.goals g
      left join public.profiles a on a.id = g.assignee_id
      where g.group_id = p_group_id
    ) t
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_goals(uuid) to authenticated;

create or replace function public.get_goal_detail(p_goal_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_group_id uuid;
  v_result jsonb;
begin
  select group_id into v_group_id from public.goals where id = p_goal_id;
  if v_group_id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;
  if not public.is_group_member(v_group_id) then
    raise exception 'グループのメンバーではありません' using errcode = '42501';
  end if;

  select jsonb_build_object(
    'id', g.id,
    'header', g.header,
    'description', g.description,
    'deadline', g.deadline,
    'isConcrete', g.is_concrete,
    'isCompleted', g.is_completed,
    'status', public.calc_goal_status(g.is_completed, g.deadline, g.assignee_id),
    'createdAt', g.created_at,
    'updatedAt', g.updated_at,
    'groupId', g.group_id,
    'assigneeId', g.assignee_id,
    'assignee', case when a.id is null then null
      else jsonb_build_object('id', a.id, 'email', a.email, 'name', a.name, 'avatar', a.avatar)
    end,
    'progress', public.calc_vote_progress(g.id),
    'group', jsonb_build_object(
      'id', grp.id,
      'name', grp.name,
      'members', (
        select coalesce(jsonb_agg(jsonb_build_object('id', mp.id, 'email', mp.email, 'name', mp.name, 'avatar', mp.avatar)), '[]'::jsonb)
        from public.group_members gm join public.profiles mp on mp.id = gm.user_id
        where gm.group_id = grp.id
      )
    )
  )
  into v_result
  from public.goals g
  join public.groups grp on grp.id = g.group_id
  left join public.profiles a on a.id = g.assignee_id
  where g.id = p_goal_id;

  return v_result;
end;
$$;

grant execute on function public.get_goal_detail(uuid) to authenticated;

create or replace function public.create_goal(
  p_group_id uuid,
  p_description text,
  p_header text default null,
  p_deadline timestamptz default null,
  p_assignee_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_goal_id uuid;
begin
  if not public.is_group_member(p_group_id) then
    raise exception 'グループのメンバーではありません' using errcode = '42501';
  end if;

  insert into public.goals (group_id, header, description, deadline, assignee_id)
  values (p_group_id, p_header, p_description, p_deadline, p_assignee_id)
  returning id into v_goal_id;

  return public.get_goal_detail(v_goal_id) - 'group';
end;
$$;

grant execute on function public.create_goal(uuid, text, text, timestamptz, uuid) to authenticated;

create or replace function public.update_goal(p_goal_id uuid, p_data jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  select group_id into v_group_id from public.goals where id = p_goal_id;
  if v_group_id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;
  if not public.is_group_member(v_group_id) then
    raise exception 'グループのメンバーではありません' using errcode = '42501';
  end if;

  update public.goals set
    header = case when p_data ? 'header' then p_data ->> 'header' else header end,
    description = case when p_data ? 'description' then p_data ->> 'description' else description end,
    deadline = case when p_data ? 'deadline' then (p_data ->> 'deadline')::timestamptz else deadline end,
    assignee_id = case when p_data ? 'assigneeId' then (p_data ->> 'assigneeId')::uuid else assignee_id end,
    updated_at = now()
  where id = p_goal_id;

  return public.get_goal_detail(p_goal_id) - 'group';
end;
$$;

grant execute on function public.update_goal(uuid, jsonb) to authenticated;

create or replace function public.delete_goal(p_goal_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  select group_id into v_group_id from public.goals where id = p_goal_id;
  if v_group_id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;
  if not public.is_group_member(v_group_id) then
    raise exception 'グループのメンバーではありません' using errcode = '42501';
  end if;

  delete from public.goals where id = p_goal_id;
end;
$$;

grant execute on function public.delete_goal(uuid) to authenticated;

-- =====================================================================
-- RPC: votes
-- =====================================================================

create or replace function public.get_vote_status(p_goal_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_goal public.goals;
  v_total_members integer;
begin
  select * into v_goal from public.goals where id = p_goal_id;
  if v_goal.id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;
  if not public.is_group_member(v_goal.group_id) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  select count(*) into v_total_members from public.group_members where group_id = v_goal.group_id;

  return jsonb_build_object(
    'goalId', v_goal.id,
    'isCompleted', v_goal.is_completed,
    'progress', public.calc_vote_progress(p_goal_id),
    'totalMembers', v_total_members,
    'votes', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'voter', jsonb_build_object('id', p.id, 'email', p.email, 'name', p.name, 'avatar', p.avatar),
        'isYes', v.is_yes
      )), '[]'::jsonb)
      from public.goal_votes gv
      join public.profiles p on p.id = gv.voter_id
      left join public.votes v on v.goal_vote_id = gv.id
      where gv.goal_id = p_goal_id
    ),
    'myVote', (
      select v.is_yes from public.goal_votes gv
      left join public.votes v on v.goal_vote_id = gv.id
      where gv.goal_id = p_goal_id and gv.voter_id = auth.uid()
    )
  );
end;
$$;

grant execute on function public.get_vote_status(uuid) to authenticated;

create or replace function public.cast_vote(p_goal_id uuid, p_is_yes boolean)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_goal public.goals;
  v_goal_vote_id uuid;
  v_progress integer;
  v_just_completed boolean := false;
begin
  select * into v_goal from public.goals where id = p_goal_id;
  if v_goal.id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;
  if not public.is_group_member(v_goal.group_id) then
    raise exception 'グループのメンバーではありません' using errcode = '42501';
  end if;
  if v_goal.is_completed then
    raise exception 'このゴールはすでに達成済みです' using errcode = '22023';
  end if;
  if v_goal.is_concrete and v_goal.deadline < now() then
    raise exception 'このゴールは期限切れのため投票できません' using errcode = '22023';
  end if;

  insert into public.goal_votes (goal_id, voter_id)
  values (p_goal_id, auth.uid())
  on conflict (goal_id, voter_id) do nothing;

  select id into v_goal_vote_id from public.goal_votes where goal_id = p_goal_id and voter_id = auth.uid();

  insert into public.votes (goal_vote_id, goal_id, voter_id, is_yes)
  values (v_goal_vote_id, p_goal_id, auth.uid(), p_is_yes)
  on conflict (goal_vote_id) do update set is_yes = excluded.is_yes, created_at = now();

  v_progress := public.calc_vote_progress(p_goal_id);

  if v_progress >= 90 then
    update public.goals set is_completed = true, updated_at = now() where id = p_goal_id;
    v_just_completed := true;
  end if;

  perform public.recalc_group_score(v_goal.group_id);

  return jsonb_build_object('ok', true, 'isYes', p_is_yes, 'progress', v_progress, 'justCompleted', v_just_completed);
end;
$$;

grant execute on function public.cast_vote(uuid, boolean) to authenticated;

create or replace function public.cancel_vote(p_goal_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
  v_goal_vote_id uuid;
  v_progress integer;
begin
  select group_id into v_group_id from public.goals where id = p_goal_id;
  if v_group_id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;

  select id into v_goal_vote_id from public.goal_votes where goal_id = p_goal_id and voter_id = auth.uid();
  if v_goal_vote_id is null then
    raise exception '投票が存在しません' using errcode = 'P0002';
  end if;

  delete from public.votes where goal_vote_id = v_goal_vote_id;

  v_progress := public.calc_vote_progress(p_goal_id);
  perform public.recalc_group_score(v_group_id);

  return jsonb_build_object('ok', true, 'progress', v_progress);
end;
$$;

grant execute on function public.cancel_vote(uuid) to authenticated;

-- =====================================================================
-- RPC: messages
-- =====================================================================

create or replace function public.get_messages(p_goal_id uuid)
returns jsonb
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_group_id uuid;
begin
  select group_id into v_group_id from public.goals where id = p_goal_id;
  if v_group_id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;
  if not public.is_group_member(v_group_id) then
    raise exception 'アクセス権がありません' using errcode = '42501';
  end if;

  return coalesce((
    select jsonb_agg(to_jsonb(t) order by t."createdAt" asc)
    from (
      select
        m.id, m.text, m.created_at as "createdAt", m.goal_id as "goalId", m.author_id as "authorId",
        jsonb_build_object('id', a.id, 'email', a.email, 'name', a.name, 'avatar', a.avatar) as author
      from public.messages m
      join public.profiles a on a.id = m.author_id
      where m.goal_id = p_goal_id
    ) t
  ), '[]'::jsonb);
end;
$$;

grant execute on function public.get_messages(uuid) to authenticated;

create or replace function public.send_message(p_goal_id uuid, p_text text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
  v_message public.messages;
begin
  select group_id into v_group_id from public.goals where id = p_goal_id;
  if v_group_id is null then
    raise exception 'ゴールが存在しません' using errcode = 'P0002';
  end if;
  if not public.is_group_member(v_group_id) then
    raise exception 'グループのメンバーではありません' using errcode = '42501';
  end if;

  insert into public.messages (goal_id, author_id, text)
  values (p_goal_id, auth.uid(), p_text)
  returning * into v_message;

  return jsonb_build_object(
    'id', v_message.id,
    'text', v_message.text,
    'createdAt', v_message.created_at,
    'goalId', v_message.goal_id,
    'authorId', v_message.author_id,
    'author', (select jsonb_build_object('id', id, 'email', email, 'name', name, 'avatar', avatar) from public.profiles where id = auth.uid())
  );
end;
$$;

grant execute on function public.send_message(uuid, text) to authenticated;

-- =====================================================================
-- RPC: rankings（未ログインでも閲覧可）
-- =====================================================================

create or replace function public.get_rankings(p_limit integer default 20)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t)), '[]'::jsonb)
  from (
    select
      g.id, g.name, g.tag, g.score, g.streak, g.created_at as "createdAt",
      jsonb_build_object('id', o.id, 'email', o.email, 'name', o.name, 'avatar', o.avatar) as owner,
      jsonb_build_object(
        'members', (select count(*) from public.group_members gm where gm.group_id = g.id),
        'goals', (select count(*) from public.goals gl where gl.group_id = g.id)
      ) as "_count"
    from public.groups g
    join public.profiles o on o.id = g.owner_id
    where g.is_public = true
    order by g.score desc
    limit least(greatest(coalesce(p_limit, 20), 1), 100)
  ) t;
$$;

grant execute on function public.get_rankings(integer) to authenticated, anon;
