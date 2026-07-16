export type NotificationKind = 'pending_vote' | 'deadline_approaching' | 'missed'

export interface NotificationItem {
  id: string
  kind: NotificationKind
  sentAt: string
  readAt: string | null
  goalId: string
  goalHeader: string | null
  goalDescription: string
  groupId: string
  groupName: string
}
