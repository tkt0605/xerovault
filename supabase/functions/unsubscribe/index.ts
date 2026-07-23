// notify-digestのメール本文に埋め込まれたリンクから呼ばれる、
// ログイン不要のワンタップ配信停止エンドポイント。
// tokenはprofiles.unsubscribe_token（推測困難なuuid）と一致した場合のみ
// notifications_enabledをfalseにする。結果は簡潔な確認ページで返す。

import { createClient } from 'npm:@supabase/supabase-js@2'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

Deno.serve(async (req) => {
  const token = new URL(req.url).searchParams.get('token')

  if (!token) {
    return page('リンクが正しくありません。', 400)
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey)
  const { data, error } = await supabase.rpc('disable_notifications_by_token', { p_token: token })

  if (error || !data) {
    return page('リンクが正しくないか、すでに配信停止済みです。', 400)
  }

  return page('配信を停止しました。またいつでもお待ちしています。')
})

function page(message: string, status = 200) {
  const html = `<!doctype html>
<html lang="ja">
<head><meta charset="utf-8"><title>Sodalis</title></head>
<body style="font-family: sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; color: #333;">
  <p>${message}</p>
</body>
</html>`
  return new Response(html, { status, headers: { 'content-type': 'text/html; charset=utf-8' } })
}
