import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Goal, CreateGoalInput, UpdateGoalInput } from '@xerovault/shared'
import { api } from '@/api/client'

export type { Goal }

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

  async function createGoal(groupId: string, data: CreateGoalInput): Promise<Goal> {
    const g = await api.post<Goal>(`/groups/${groupId}/goals`, data)
    goals.value.unshift(g)
    return g
  }

  async function updateGoal(id: string, data: UpdateGoalInput): Promise<Goal> {
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
