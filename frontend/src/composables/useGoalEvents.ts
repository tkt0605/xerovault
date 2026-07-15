import { onUnmounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

const RECONNECT_DELAY_MS = 3000

interface GoalEventHandlers {
  onVote?: () => void
  onMessage?: (payload: unknown) => void
}

// fetch + ReadableStreamでSSEを読む(EventSourceはAuthorizationヘッダーを付けられないため)
export function useGoalEvents(goalId: string, handlers: GoalEventHandlers): void {
  const auth = useAuthStore()
  const controller = new AbortController()
  let stopped = false

  async function connect(): Promise<void> {
    try {
      const res = await fetch(`/api/goals/${goalId}/events`, {
        headers: { Authorization: `Bearer ${auth.accessToken}` },
        credentials: 'include',
        signal: controller.signal,
      })
      if (!res.body) return

      const reader = res.body.getReader()
      const decoder = new TextDecoder()
      let buffer = ''

      while (true) {
        const { value, done } = await reader.read()
        if (done) break
        buffer += decoder.decode(value, { stream: true })

        const rawEvents = buffer.split('\n\n')
        buffer = rawEvents.pop() ?? ''

        for (const rawEvent of rawEvents) {
          let eventName = 'message'
          let data = ''
          for (const line of rawEvent.split('\n')) {
            if (line.startsWith('event:')) eventName = line.slice(6).trim()
            else if (line.startsWith('data:')) data = line.slice(5).trim()
          }
          if (!data || eventName === 'connected') continue

          if (eventName === 'vote') handlers.onVote?.()
          if (eventName === 'message') handlers.onMessage?.(JSON.parse(data))
        }
      }
    } catch (err) {
      if ((err as Error).name === 'AbortError') return
    }

    if (!stopped) setTimeout(connect, RECONNECT_DELAY_MS)
  }

  connect()

  onUnmounted(() => {
    stopped = true
    controller.abort()
  })
}
