import { onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

// Supabase Realtime(postgres_changes)で自分宛の新着通知を購読する
export function useNotificationEvents(userId: string, onInsert: () => void): void {
  const channel = supabase
    .channel(`notification:${userId}`)
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'notification_log', filter: `user_id=eq.${userId}` },
      () => onInsert()
    )
    .subscribe()

  onUnmounted(() => {
    supabase.removeChannel(channel)
  })
}
