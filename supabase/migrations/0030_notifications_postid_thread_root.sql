-- =====================================================================
-- get_my_notificationsのreply種別のpostIdを、返信メッセージ自身のidから
-- スレッドのルートidへ変更する。
--
-- スレッドはルートに正規化される構造(0029)になっており、フロントの
-- ThreadDetail.vueはURLのthreadIdをそのままRealtime購読のフィルタに
-- 使う設計。返信メッセージ自身のid(=ルートではない)がpostIdとして
-- 返ってくると、フロント側で改めて非同期にルートを解決する必要が生じ、
-- コンポーネントのライフサイクル管理が複雑になる(実際にonUnmountedの
-- 登録タイミング違反を引き起こした)。DB側でルートidを返せば、通知からの
-- 遷移も一覧からの遷移も同じ「常にルートid」という前提で扱えて単純になる。
-- =====================================================================

create or replace function public.get_my_notifications(p_limit integer default 30)
returns jsonb
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(jsonb_agg(to_jsonb(t) order by t."sentAt" desc), '[]'::jsonb)
  from (
    select
      nl.id,
      nl.kind,
      nl.sent_at as "sentAt",
      nl.read_at as "readAt",
      g.id as "goalId",
      g.header as "goalHeader",
      g.description as "goalDescription",
      coalesce(goalgrp.id, postgrp.id) as "groupId",
      coalesce(goalgrp.name, postgrp.name) as "groupName",
      coalesce(gp.parent_post_id, gp.id) as "postId",
      gp.text as "replyText",
      ra.name as "replierName"
    from public.notification_log nl
    left join public.goals g on g.id = nl.goal_id
    left join public.groups goalgrp on goalgrp.id = g.group_id
    left join public.group_posts gp on gp.id = nl.group_post_id
    left join public.groups postgrp on postgrp.id = gp.group_id
    left join public.profiles ra on ra.id = gp.author_id
    where nl.user_id = auth.uid()
    order by nl.sent_at desc
    limit p_limit
  ) t;
$$;

grant execute on function public.get_my_notifications(integer) to authenticated;
