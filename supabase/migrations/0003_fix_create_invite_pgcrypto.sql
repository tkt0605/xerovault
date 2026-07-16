-- =====================================================================
-- create_invite が "function gen_random_bytes(integer) does not exist" で
-- 失敗する不具合の修正。
--
-- Supabaseではpgcryptoが`public`ではなく`extensions`スキーマにインストール
-- されるため、search_path=publicに固定したSECURITY DEFINER関数から
-- 素の gen_random_bytes(...) を呼ぶと解決できない（PostgRESTはこれを
-- 42883 undefined_function として検知し、HTTP 404を返す）。
-- 呼び出し側をextensions.gen_random_bytes(...)にスキーマ修飾して解決する。
-- =====================================================================

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

  v_token := encode(extensions.gen_random_bytes(16), 'hex');

  update public.groups
  set join_token = v_token,
      join_token_expires_at = now() + make_interval(secs => p_expire_in)
  where id = p_group_id;

  return v_token;
end;
$$;

grant execute on function public.create_invite(uuid, integer) to authenticated;
