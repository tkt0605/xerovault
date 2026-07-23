import { defineStore } from 'pinia'
import { ref } from 'vue'
import type {
  Group,
  CreateGroupInput,
  UpdateGroupInput,
  ScoreBreakdown,
  BannedMember,
  JoinRequestTarget,
  GroupJoinRequest,
  GroupActivityStats,
  GroupInvite,
} from '@xerovault/shared'
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
      p_tags: data.tags ?? [],
      p_is_public: data.isPublic ?? false,
      p_description: data.description ?? null,
    })
    groups.value.unshift(g)
    return g
  }

  async function updateGroup(groupId: string, data: UpdateGroupInput): Promise<Group> {
    const g = await rpc<Group>('update_group', {
      p_group_id: groupId,
      p_name: data.name ?? null,
      p_tags: data.tags ?? null,
      p_description: data.description ?? null,
    })
    if (current.value?.id === groupId) current.value = g
    groups.value = groups.value.map((x) => (x.id === g.id ? g : x))
    return g
  }

  // 招待コードを1件発行する（既存の他コードは失効しない。有効期限はSupabase側のRPCで検証する）
  async function createInvite(
    groupId: string,
    expireIn = 3600
  ): Promise<{ id: string; url: string; expiresAt: string }> {
    const invite = await rpc<GroupInvite>('create_invite', {
      p_group_id: groupId,
      p_expire_in: expireIn,
    })
    const origin = window.location.origin
    return {
      id: invite.id,
      url: `${origin}/group/${groupId}/join?token=${encodeURIComponent(invite.token)}`,
      expiresAt: invite.expiresAt,
    }
  }

  async function fetchInvites(
    groupId: string
  ): Promise<{ id: string; url: string; expiresAt: string }[]> {
    const list = await rpc<GroupInvite[]>('get_group_invites', { p_group_id: groupId })
    const origin = window.location.origin
    return list.map((inv) => ({
      id: inv.id,
      url: `${origin}/group/${groupId}/join?token=${encodeURIComponent(inv.token)}`,
      expiresAt: inv.expiresAt,
    }))
  }

  async function revokeInvite(inviteId: string): Promise<void> {
    await rpc('revoke_invite', { p_invite_id: inviteId })
  }

  async function joinGroup(groupId: string, token?: string): Promise<Group> {
    const group = await rpc<Group>('join_group', { p_group_id: groupId, p_token: token ?? null })
    groups.value.unshift(group)
    return group
  }

  async function removeMember(groupId: string, memberId: string): Promise<void> {
    await rpc('remove_member', { p_group_id: groupId, p_member_id: memberId })
    if (current.value?.id === groupId) {
      current.value.members = current.value.members.filter((m) => m.id !== memberId)
    }
  }

  async function fetchScoreBreakdown(groupId: string): Promise<ScoreBreakdown> {
    return await rpc<ScoreBreakdown>('get_score_breakdown', { p_group_id: groupId })
  }

  async function fetchBannedMembers(groupId: string): Promise<BannedMember[]> {
    return await rpc<BannedMember[]>('get_banned_members', { p_group_id: groupId })
  }

  async function unbanMember(groupId: string, userId: string): Promise<void> {
    await rpc('unban_member', { p_group_id: groupId, p_user_id: userId })
  }

  async function fetchJoinRequestTarget(groupId: string): Promise<JoinRequestTarget> {
    return await rpc<JoinRequestTarget>('get_group_join_request_target', { p_group_id: groupId })
  }

  async function createJoinRequest(groupId: string, message: string): Promise<void> {
    await rpc('create_join_request', { p_group_id: groupId, p_message: message || null })
  }

  async function fetchJoinRequests(groupId: string): Promise<GroupJoinRequest[]> {
    return await rpc<GroupJoinRequest[]>('get_group_join_requests', { p_group_id: groupId })
  }

  async function approveJoinRequest(requestId: string): Promise<void> {
    await rpc('approve_join_request', { p_request_id: requestId })
  }

  async function rejectJoinRequest(requestId: string): Promise<void> {
    await rpc('reject_join_request', { p_request_id: requestId })
  }

  async function fetchActivityStats(groupId: string): Promise<GroupActivityStats> {
    return await rpc<GroupActivityStats>('get_group_activity_stats', { p_group_id: groupId })
  }

  return {
    groups,
    current,
    fetchMyGroups,
    fetchGroup,
    createGroup,
    updateGroup,
    createInvite,
    fetchInvites,
    revokeInvite,
    joinGroup,
    removeMember,
    fetchScoreBreakdown,
    fetchBannedMembers,
    unbanMember,
    fetchJoinRequestTarget,
    createJoinRequest,
    fetchJoinRequests,
    approveJoinRequest,
    rejectJoinRequest,
    fetchActivityStats,
  }
})
