set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_group(p_group_id uuid, p_name text DEFAULT NULL::text, p_tags text[] DEFAULT NULL::text[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;

grant delete on table "public"."goal_votes" to "anon";

grant insert on table "public"."goal_votes" to "anon";

grant select on table "public"."goal_votes" to "anon";

grant update on table "public"."goal_votes" to "anon";

grant delete on table "public"."goal_votes" to "authenticated";

grant insert on table "public"."goal_votes" to "authenticated";

grant select on table "public"."goal_votes" to "authenticated";

grant update on table "public"."goal_votes" to "authenticated";

grant delete on table "public"."goal_votes" to "service_role";

grant insert on table "public"."goal_votes" to "service_role";

grant select on table "public"."goal_votes" to "service_role";

grant update on table "public"."goal_votes" to "service_role";

grant delete on table "public"."goals" to "anon";

grant insert on table "public"."goals" to "anon";

grant select on table "public"."goals" to "anon";

grant update on table "public"."goals" to "anon";

grant delete on table "public"."goals" to "authenticated";

grant insert on table "public"."goals" to "authenticated";

grant select on table "public"."goals" to "authenticated";

grant update on table "public"."goals" to "authenticated";

grant delete on table "public"."goals" to "service_role";

grant insert on table "public"."goals" to "service_role";

grant select on table "public"."goals" to "service_role";

grant update on table "public"."goals" to "service_role";

grant delete on table "public"."group_members" to "anon";

grant insert on table "public"."group_members" to "anon";

grant select on table "public"."group_members" to "anon";

grant update on table "public"."group_members" to "anon";

grant delete on table "public"."group_members" to "authenticated";

grant insert on table "public"."group_members" to "authenticated";

grant select on table "public"."group_members" to "authenticated";

grant update on table "public"."group_members" to "authenticated";

grant delete on table "public"."group_members" to "service_role";

grant insert on table "public"."group_members" to "service_role";

grant select on table "public"."group_members" to "service_role";

grant update on table "public"."group_members" to "service_role";

grant delete on table "public"."groups" to "anon";

grant insert on table "public"."groups" to "anon";

grant select on table "public"."groups" to "anon";

grant update on table "public"."groups" to "anon";

grant delete on table "public"."groups" to "authenticated";

grant insert on table "public"."groups" to "authenticated";

grant select on table "public"."groups" to "authenticated";

grant update on table "public"."groups" to "authenticated";

grant delete on table "public"."groups" to "service_role";

grant insert on table "public"."groups" to "service_role";

grant select on table "public"."groups" to "service_role";

grant update on table "public"."groups" to "service_role";

grant delete on table "public"."messages" to "anon";

grant insert on table "public"."messages" to "anon";

grant select on table "public"."messages" to "anon";

grant update on table "public"."messages" to "anon";

grant delete on table "public"."messages" to "authenticated";

grant insert on table "public"."messages" to "authenticated";

grant select on table "public"."messages" to "authenticated";

grant update on table "public"."messages" to "authenticated";

grant delete on table "public"."messages" to "service_role";

grant insert on table "public"."messages" to "service_role";

grant select on table "public"."messages" to "service_role";

grant update on table "public"."messages" to "service_role";

grant delete on table "public"."notification_log" to "anon";

grant insert on table "public"."notification_log" to "anon";

grant select on table "public"."notification_log" to "anon";

grant update on table "public"."notification_log" to "anon";

grant delete on table "public"."notification_log" to "authenticated";

grant insert on table "public"."notification_log" to "authenticated";

grant select on table "public"."notification_log" to "authenticated";

grant update on table "public"."notification_log" to "authenticated";

grant delete on table "public"."notification_log" to "service_role";

grant insert on table "public"."notification_log" to "service_role";

grant select on table "public"."notification_log" to "service_role";

grant update on table "public"."notification_log" to "service_role";

grant delete on table "public"."profiles" to "anon";

grant insert on table "public"."profiles" to "anon";

grant delete on table "public"."profiles" to "authenticated";

grant insert on table "public"."profiles" to "authenticated";

grant delete on table "public"."profiles" to "service_role";

grant insert on table "public"."profiles" to "service_role";

grant select on table "public"."profiles" to "service_role";

grant update on table "public"."profiles" to "service_role";

grant delete on table "public"."user_plans" to "anon";

grant insert on table "public"."user_plans" to "anon";

grant select on table "public"."user_plans" to "anon";

grant update on table "public"."user_plans" to "anon";

grant delete on table "public"."user_plans" to "authenticated";

grant insert on table "public"."user_plans" to "authenticated";

grant select on table "public"."user_plans" to "authenticated";

grant update on table "public"."user_plans" to "authenticated";

grant delete on table "public"."user_plans" to "service_role";

grant insert on table "public"."user_plans" to "service_role";

grant select on table "public"."user_plans" to "service_role";

grant update on table "public"."user_plans" to "service_role";

grant delete on table "public"."votes" to "anon";

grant insert on table "public"."votes" to "anon";

grant select on table "public"."votes" to "anon";

grant update on table "public"."votes" to "anon";

grant delete on table "public"."votes" to "authenticated";

grant insert on table "public"."votes" to "authenticated";

grant select on table "public"."votes" to "authenticated";

grant update on table "public"."votes" to "authenticated";

grant delete on table "public"."votes" to "service_role";

grant insert on table "public"."votes" to "service_role";

grant select on table "public"."votes" to "service_role";

grant update on table "public"."votes" to "service_role";


