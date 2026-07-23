import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { VoteStatus, CastVoteResponse, CancelVoteResponse } from '@sodalis/shared'
import { rpc } from '@/lib/rpc'

export type { VoteStatus }

export const useVoteStore = defineStore('vote', () => {
  const status = ref<VoteStatus | null>(null)
  const justCompleted = ref(false)

  async function fetchVoteStatus(goalId: string): Promise<VoteStatus> {
    const s = await rpc<VoteStatus>('get_vote_status', { p_goal_id: goalId })
    status.value = s
    return s
  }

  async function castVote(
    goalId: string,
    isYes: boolean
  ): Promise<{ progress: number; justCompleted: boolean }> {
    const res = await rpc<CastVoteResponse>('cast_vote', { p_goal_id: goalId, p_is_yes: isYes })
    if (status.value) {
      status.value.progress = res.progress
      status.value.myVote = isYes
      if (res.justCompleted) status.value.isCompleted = true
    }
    justCompleted.value = res.justCompleted
    return { progress: res.progress, justCompleted: res.justCompleted }
  }

  async function cancelVote(goalId: string): Promise<void> {
    const res = await rpc<CancelVoteResponse>('cancel_vote', { p_goal_id: goalId })
    if (status.value) {
      status.value.progress = res.progress
      status.value.myVote = null
    }
  }

  return { status, justCompleted, fetchVoteStatus, castVote, cancelVote }
})
