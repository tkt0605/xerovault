import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/api/client'

export interface VoteStatus {
  goalId: string
  isCompleted: boolean
  progress: number
  totalMembers: number
  myVote: boolean | null
  votes: {
    voter: { id: string; email: string; name: string | null; avatar: string | null }
    isYes: boolean | null
  }[]
}

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
    const res = await api.post<{
      ok: boolean
      isYes: boolean
      progress: number
      justCompleted: boolean
    }>(`/goals/${goalId}/votes`, { isYes })
    if (status.value) {
      status.value.progress = res.progress
      status.value.myVote = isYes
      if (res.justCompleted) status.value.isCompleted = true
    }
    justCompleted.value = res.justCompleted
    return { progress: res.progress, justCompleted: res.justCompleted }
  }

  async function cancelVote(goalId: string): Promise<void> {
    const res = await api.delete<{ ok: boolean; progress: number }>(`/goals/${goalId}/votes`)
    if (status.value) {
      status.value.progress = res.progress
      status.value.myVote = null
    }
  }

  return { status, justCompleted, fetchVoteStatus, castVote, cancelVote }
})
