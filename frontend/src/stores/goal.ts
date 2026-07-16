import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Goal, CreateGoalInput, UpdateGoalInput } from '@xerovault/shared'
import { rpc } from '@/lib/rpc'

export type { Goal }

export const useGoalStore = defineStore('goal', () => {
  const goals = ref<Goal[]>([])
  const current = ref<Goal | null>(null)

  async function fetchGoals(groupId: string): Promise<Goal[]> {
    goals.value = await rpc<Goal[]>('get_goals', { p_group_id: groupId })
    return goals.value
  }

  async function fetchGoal(id: string): Promise<Goal> {
    const g = await rpc<Goal>('get_goal_detail', { p_goal_id: id })
    current.value = g
    return g
  }

  async function createGoal(groupId: string, data: CreateGoalInput): Promise<Goal> {
    const g = await rpc<Goal>('create_goal', {
      p_group_id: groupId,
      p_description: data.description,
      p_header: data.header ?? null,
      p_deadline: data.deadline ?? null,
      p_assignee_id: data.assigneeId ?? null,
    })
    goals.value.unshift(g)
    return g
  }

  async function updateGoal(id: string, data: UpdateGoalInput): Promise<Goal> {
    const g = await rpc<Goal>('update_goal', { p_goal_id: id, p_data: data })
    const idx = goals.value.findIndex((x) => x.id === id)
    if (idx !== -1) goals.value[idx] = g
    if (current.value?.id === id) current.value = g
    return g
  }

  async function deleteGoal(id: string): Promise<void> {
    await rpc('delete_goal', { p_goal_id: id })
    goals.value = goals.value.filter((g) => g.id !== id)
  }

  return { goals, current, fetchGoals, fetchGoal, createGoal, updateGoal, deleteGoal }
})
