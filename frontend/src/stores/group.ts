import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/api/client'

export interface Group {
  id: string
  name: string
  tag: string | null
  isPublic: boolean
  score: number
  streak: number
  credits: number
  joinToken: string | null
  createdAt: string
  updatedAt: string
  owner: { id: string; email: string; avatar: string | null }
  members: { id: string; email: string; avatar: string | null }[]
  _count: { goals: number }
}

export const useGroupStore = defineStore('group', () => {
  const groups = ref<Group[]>([])
  const current = ref<Group | null>(null)

  async function fetchMyGroups(): Promise<void> {
    groups.value = await api.get<Group[]>('/groups')
  }

  async function fetchGroup(id: string): Promise<Group> {
    const g = await api.get<Group>(`/groups/${id}`)
    current.value = g
    return g
  }

  async function createGroup(data: { name: string; tag?: string; isPublic?: boolean }): Promise<Group> {
    const g = await api.post<Group>('/groups', data)
    groups.value.unshift(g)
    return g
  }

  async function createInvite(groupId: string): Promise<string> {
    const res = await api.post<{ encryptedData: string }>(`/groups/${groupId}/invite`, { expireIn: 3600 })
    const origin = window.location.origin
    return `${origin}/studio/${groupId}/join?data=${encodeURIComponent(res.encryptedData)}`
  }

  async function joinGroup(groupId: string, data: string): Promise<Group> {
    const res = await api.post<{ group: Group }>(`/groups/${groupId}/join`, { data })
    groups.value.unshift(res.group)
    return res.group
  }

  async function removeMember(groupId: string, memberId: string): Promise<void> {
    await api.delete(`/groups/${groupId}/members/${memberId}`)
    if (current.value?.id === groupId) {
      current.value.members = current.value.members.filter((m) => m.id !== memberId)
    }
  }

  return { groups, current, fetchMyGroups, fetchGroup, createGroup, createInvite, joinGroup, removeMember }
})
