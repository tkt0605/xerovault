import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { VoteStatus, CastVoteResponse, CancelVoteResponse } from '@xerovault/shared'
import { api } from '@/api/client'

export type { VoteStatus }

export const useVoteStore = defineStore('vote', () => {
  const status = ref<VoteStatus | null>(null)
  const justCompleted = ref(false)

  async function fetchVoteStatus(goalId: string): Promise<VoteStatus> {
    const s = await api.get<VoteStatus>(`/goals/${goalId}/votes`)
    status.value = s
    return s
  }

  async function castVote(
    goalId: string,
    isYes: boolean
  ): Promise<{ progress: number; justCompleted: boolean }> {
    const res = await api.post<CastVoteResponse>(`/goals/${goalId}/votes`, { isYes })
    if (status.value) {
      status.value.progress = res.progress
      status.value.myVote = isYes
      if (res.justCompleted) status.value.isCompleted = true
    }
    justCompleted.value = res.justCompleted
    return { progress: res.progress, justCompleted: res.justCompleted }
  }

  async function cancelVote(goalId: string): Promise<void> {
    const res = await api.delete<CancelVoteResponse>(`/goals/${goalId}/votes`)
    if (status.value) {
      status.value.progress = res.progress
      status.value.myVote = null
    }
  }

  return { status, justCompleted, fetchVoteStatus, castVote, cancelVote }
})
