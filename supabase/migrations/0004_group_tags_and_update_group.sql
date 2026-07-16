  -- =====================================================================
  -- groups.tag (単一文字列) を groups.tags (複数タグの配列) に変更し、
  -- オーナー専用の update_group RPC を追加する
  -- =====================================================================

  alter table public.groups add column tags text[] not null default '{}';

  update public.groups
  set tags = (
    select coalesce(array_agg(distinct trim(t)) filter (where trim(t) <> ''), '{}')
    from unnest(string_to_array(coalesce(tag, ''), ',')) as t
  );

  alter table public.groups drop column tag;

  -- ---------------------------------------------------------------------
  -- get_group_detail: tag -> tags
  -- ---------------------------------------------------------------------
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
      'tags', g.tags,
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

  -- ---------------------------------------------------------------------
  -- get_my_groups: tag -> tags
  -- ---------------------------------------------------------------------
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
        g.tags,
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

  -- ---------------------------------------------------------------------
  -- create_group: p_tag text -> p_tags text[]
  -- ---------------------------------------------------------------------
  drop function if exists public.create_group(text, text, boolean);

  create or replace function public.create_group(p_name text, p_tags text[] default '{}', p_is_public boolean default false)
  returns jsonb
  language plpgsql
  security definer
  set search_path = public
  as $$
  declare
    v_group_id uuid;
    v_tags text[];
  begin
    select coalesce(array_agg(distinct trim(t)) filter (where trim(t) <> ''), '{}')
    into v_tags
    from unnest(coalesce(p_tags, '{}')) as t;

    insert into public.groups (name, tags, is_public, owner_id)
    values (p_name, v_tags, coalesce(p_is_public, false), auth.uid())
    returning id into v_group_id;

    insert into public.group_members (group_id, user_id) values (v_group_id, auth.uid());

    return public.get_group_detail(v_group_id);
  end;
  $$;

  grant execute on function public.create_group(text, text[], boolean) to authenticated;

  -- ---------------------------------------------------------------------
  -- update_group: オーナーのみ名前・タグを更新できる
  -- ---------------------------------------------------------------------
  create or replace function public.update_group(p_group_id uuid, p_name text default null, p_tags text[] default null)
  returns jsonb
  language plpgsql
  security definer
  set search_path = public
  as $$
  declare
    v_tags text[];
  begin
    if not exists (select 1 from public.groups where id = p_group_id and owner_id = auth.uid()) then
      raise exception 'オーナーのみ編集できます' using errcode = '42501';
    end if;

    if p_tags is not null then
      select coalesce(array_agg(distinct trim(t)) filter (where trim(t) <> ''), '{}')
      into v_tags
      from unnest(p_tags) as t;
    end if;

    update public.groups
    set
      name = coalesce(nullif(trim(p_name), ''), name),
      tags = coalesce(v_tags, tags),
      updated_at = now()
    where id = p_group_id;

    return public.get_group_detail(p_group_id);
  end;
  $$;

  grant execute on function public.update_group(uuid, text, text[]) to authenticated;

  -- ---------------------------------------------------------------------
  -- get_rankings: tag -> tags
  -- ---------------------------------------------------------------------
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
        g.id, g.name, g.tags, g.score, g.streak, g.created_at as "createdAt",
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
