import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/api/client'

export interface Goal {
  id: string
  header: string | null
  description: string
  deadline: string | null
  isConcrete: boolean
  isCompleted: boolean
  progress: number
  createdAt: string
  groupId: string
  assignee: { id: string; email: string; name: string | null; avatar: string | null } | null
  group?: {
    id: string
    name: string
    members: { id: string; email: string; name: string | null; avatar: string | null }[]
  }
}

export const useGoalStore = defineStore('goal', () => {
  const goals = ref<Goal[]>([])
  const current = ref<Goal | null>(null)

  async function fetchGoals(groupId: string): Promise<Goal[]> {
    goals.value = await api.get<Goal[]>(`/groups/${groupId}/goals`)
    return goals.value
  }

  async function fetchGoal(id: string): Promise<Goal> {
    const g = await api.get<Goal>(`/goals/${id}`)
    current.value = g
    return g
  }

  async function createGoal(
    groupId: string,
    data: {
      header?: string
      description: string
      deadline?: string | null
      assigneeId?: string | null
    }
  ): Promise<Goal> {
    const g = await api.post<Goal>(`/groups/${groupId}/goals`, data)
    goals.value.unshift(g)
    return g
  }

  async function updateGoal(id: string, data: Partial<Goal>): Promise<Goal> {
    const g = await api.patch<Goal>(`/goals/${id}`, data)
    const idx = goals.value.findIndex((x) => x.id === id)
    if (idx !== -1) goals.value[idx] = g
    if (current.value?.id === id) current.value = g
    return g
  }

  async function deleteGoal(id: string): Promise<void> {
    await api.delete(`/goals/${id}`)
    goals.value = goals.value.filter((g) => g.id !== id)
  }

  return { goals, current, fetchGoals, fetchGoal, createGoal, updateGoal, deleteGoal }
})
