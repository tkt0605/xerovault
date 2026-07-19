import { onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

// Supabase Realtime(postgres_changes)でスレッド内の新規メッセージを購読する。
// group_posts.parent_post_idはスレッドのルート投稿へ正規化されているため、
// このフィルタだけでスレッド内の全メッセージ(ルートへの返信)を捕捉できる。
export function useThreadEvents(threadId: string, onMessage: () => void): void {
  const channel = supabase
    .channel(`thread:${threadId}`)
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'group_posts',
        filter: `parent_post_id=eq.${threadId}`,
      },
      () => onMessage()
    )
    .subscribe()

  onUnmounted(() => {
    supabase.removeChannel(channel)
  })
}
