import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Group, CreateGroupInput } from '@xerovault/shared'
import { rpc } from '@/lib/rpc'

export type { Group }

export const useGroupStore = defineStore('group', () => {
  const groups = ref<Group[]>([])
  const current = ref<Group | null>(null)

  async function fetchMyGroups(): Promise<void> {
    groups.value = await rpc<Group[]>('get_my_groups')
  }

  async function fetchGroup(id: string): Promise<Group> {
    const g = await rpc<Group>('get_group_detail', { p_group_id: id })
    current.value = g
    return g
  }

  async function createGroup(data: CreateGroupInput): Promise<Group> {
    const g = await rpc<Group>('create_group', {
      p_name: data.name,
      p_tag: data.tag ?? null,
      p_is_public: data.isPublic ?? false,
    })
    groups.value.unshift(g)
    return g
  }

  // 招待リンクを発行する（トークンは平文。有効期限はSupabase側のRPCで検証する）
  async function createInvite(groupId: string): Promise<string> {
    const token = await rpc<string>('create_invite', { p_group_id: groupId, p_expire_in: 3600 })
    const origin = window.location.origin
    return `${origin}/group/${groupId}/join?token=${encodeURIComponent(token)}`
  }

  async function joinGroup(groupId: string, token: string): Promise<Group> {
    const group = await rpc<Group>('join_group', { p_group_id: groupId, p_token: token })
    groups.value.unshift(group)
    return group
  }

  async function removeMember(groupId: string, memberId: string): Promise<void> {
    await rpc('remove_member', { p_group_id: groupId, p_member_id: memberId })
    if (current.value?.id === groupId) {
      current.value.members = current.value.members.filter((m) => m.id !== memberId)
    }
  }

  return {
    groups,
    current,
    fetchMyGroups,
    fetchGroup,
    createGroup,
    createInvite,
    joinGroup,
    removeMember,
  }
})
