import { EventEmitter } from 'events'

// プロセス内のシンプルなpub/sub。複数インスタンスにスケールする場合はRedis等への置き換えが必要
const emitter = new EventEmitter()
emitter.setMaxListeners(0)

export type GoalEventName = 'vote' | 'message'

function channelOf(goalId: string): string {
  return `goal:${goalId}`
}

export function publishGoalEvent(goalId: string, eventName: GoalEventName, payload: unknown): void {
  emitter.emit(channelOf(goalId), eventName, payload)
}

export function subscribeGoalEvents(
  goalId: string,
  handler: (eventName: GoalEventName, payload: unknown) => void
): () => void {
  const channel = channelOf(goalId)
  emitter.on(channel, handler)
  return () => emitter.off(channel, handler)
}
