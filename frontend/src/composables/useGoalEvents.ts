import { onUnmounted } from 'vue'
import { supabase } from '@/lib/supabase'

interface GoalEventHandlers {
  onVote?: () => void
  onMessage?: () => void
}

// Supabase Realtime(postgres_changes)で投票・メッセージの変更を購読する
export function useGoalEvents(goalId: string, handlers: GoalEventHandlers): void {
  const channel = supabase
    .channel(`goal:${goalId}`)
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'votes', filter: `goal_id=eq.${goalId}` },
      () => handlers.onVote?.()
    )
    .on(
      'postgres_changes',
      { event: 'INSERT', schema: 'public', table: 'messages', filter: `goal_id=eq.${goalId}` },
      () => handlers.onMessage?.()
    )
    .subscribe()

  onUnmounted(() => {
    supabase.removeChannel(channel)
  })
}
