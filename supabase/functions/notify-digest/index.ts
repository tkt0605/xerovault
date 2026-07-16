// pg_cronから毎時叩かれ、投票待ち・期限接近・新規missedをユーザーごとに
// 1通のダイジェストメールにまとめて送る。
// 呼び出し元の認証はSupabaseのEdge Function標準機構（Authorization: Bearer <service_role key>
// をJWTとして検証）に任せており、このファイル内で独自のシークレット検証は行わない。

import { createClient } from 'npm:@supabase/supabase-js@2'

type Kind = 'pending_vote' | 'deadline_approaching' | 'missed'

interface Candidate {
  user_id: string
  email: string
  name: string | null
  kind: Kind
  goal_id: string
  goal_header: string | null
  goal_description: string
  group_id: string
  group_name: string
  deadline: string | null
}

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
const resendApiKey = Deno.env.get('RESEND_API_KEY')!
const fromEmail = Deno.env.get('NOTIFY_FROM_EMAIL') ?? 'Xerovault <notify@xerovault.app>'

const KIND_LABEL: Record<Kind, string> = {
  pending_vote: '投票待ち',
  deadline_approaching: '締切が近づいています',
  missed: '期限切れになりました',
}
const KIND_ORDER: Kind[] = ['missed', 'deadline_approaching', 'pending_vote']

Deno.serve(async () => {
  const supabase = createClient(supabaseUrl, serviceRoleKey)

  const { data, error } = await supabase.rpc('get_notification_candidates')
  if (error) {
    console.error('get_notification_candidates failed', error)
    return new Response(JSON.stringify({ error: error.message }), { status: 500 })
  }

  const candidates = (data ?? []) as Candidate[]
  const byUser = new Map<string, Candidate[]>()
  for (const c of candidates) {
    const list = byUser.get(c.user_id) ?? []
    list.push(c)
    byUser.set(c.user_id, list)
  }

  let usersSent = 0
  let usersFailed = 0

  for (const [userId, items] of byUser) {
    try {
      await sendDigestEmail(items)

      const rows = items.map((i) => ({ user_id: i.user_id, goal_id: i.goal_id, kind: i.kind }))
      const { error: logError } = await supabase
        .from('notification_log')
        .upsert(rows, { onConflict: 'user_id,goal_id,kind', ignoreDuplicates: true })
      if (logError) throw logError

      usersSent++
    } catch (err) {
      console.error(`digest failed for user ${userId}`, err)
      usersFailed++
    }
  }

  return new Response(
    JSON.stringify({ candidateCount: candidates.length, usersSent, usersFailed }),
    { headers: { 'content-type': 'application/json' } }
  )
})

async function sendDigestEmail(items: Candidate[]) {
  const { email, name } = items[0]

  const sections = KIND_ORDER.map((kind) => ({ kind, items: items.filter((i) => i.kind === kind) })).filter(
    (s) => s.items.length > 0
  )

  const res = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${resendApiKey}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      from: fromEmail,
      to: email,
      subject: `Xerovault: ${sections.map((s) => KIND_LABEL[s.kind]).join(' / ')}`,
      html: renderDigestHtml(name, sections),
    }),
  })

  if (!res.ok) {
    throw new Error(`resend failed: ${res.status} ${await res.text()}`)
  }
}

function renderDigestHtml(name: string | null, sections: { kind: Kind; items: Candidate[] }[]) {
  const greeting = name ? `${escapeHtml(name)}さん` : 'こんにちは'
  const body = sections
    .map(
      (s) => `
        <h2>${KIND_LABEL[s.kind]}</h2>
        <ul>
          ${s.items.map((i) => `<li>${renderItem(i)}</li>`).join('')}
        </ul>
      `
    )
    .join('')
  return `<div>${greeting}<br/>${body}</div>`
}

function renderItem(i: Candidate) {
  const title = escapeHtml(i.goal_header || i.goal_description)
  const group = escapeHtml(i.group_name)
  const deadline = i.deadline
    ? `（締切: ${new Date(i.deadline).toLocaleString('ja-JP', { dateStyle: 'medium', timeStyle: 'short' })}）`
    : ''
  return `[${group}] ${title}${deadline}`
}

function escapeHtml(s: string) {
  const map: Record<string, string> = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }
  return s.replace(/[&<>"']/g, (c) => map[c])
}
