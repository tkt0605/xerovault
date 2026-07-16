-- Basicプランのグループ数上限を 1 -> 3 に変更
-- (0012_group_count_plan_limit.sql の create_group を再定義)

create or replace function public.create_group(p_name text, p_tags text[] default '{}', p_is_public boolean default false)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_group_id uuid;
  v_tags text[];
  v_plan text;
  v_limit integer;
  v_owned integer;
begin
  v_plan := public.get_user_plan(auth.uid());
  v_limit := case v_plan
    when 'basic' then 3
    when 'pro' then 10
    else null
  end;

  if v_limit is not null then
    select count(*) into v_owned from public.groups where owner_id = auth.uid();
    if v_owned >= v_limit then
      raise exception 'オーナーとして作成できるグループ数の上限(%個)に達しています' , v_limit
        using errcode = 'P0001';
    end if;
  end if;

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
