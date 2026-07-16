-- =====================================================================
-- user_plans: 課金プラン(Basic/Pro/Enterprise)
--
-- profiles の既存RLS(users can update own profile)は行レベル(id = auth.uid())のみで
-- カラム単位の制限がないため、profiles に plan カラムを足すとクライアントから
-- supabase.from('profiles').update({ plan: 'enterprise' }) で自己アップグレードできてしまう。
-- これを避けるため、plan は別テーブルに分離し authenticated には SELECT のみ許可する
-- (INSERT/UPDATE/DELETE は service_role 専用。MVPでは手動でプランを切り替える運用)。
-- =====================================================================

create table public.user_plans (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  plan text not null default 'basic' check (plan in ('basic', 'pro', 'enterprise')),
  updated_at timestamptz not null default now()
);

alter table public.user_plans enable row level security;

create policy "users can view own plan"
  on public.user_plans for select
  to authenticated
  using (user_id = auth.uid());

-- 行が存在しないユーザーは basic 扱い(バックフィル不要)
create or replace function public.get_user_plan(p_user_id uuid)
returns text
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select plan from public.user_plans where user_id = p_user_id), 'basic');
$$;

grant execute on function public.get_user_plan(uuid) to authenticated;

-- =====================================================================
-- create_group にオーナーごとのグループ数上限ガードを追加
-- 上限: basic=1 / pro=10 / enterprise=無制限
-- =====================================================================

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
    when 'basic' then 1
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
