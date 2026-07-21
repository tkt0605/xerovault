export type NotificationKind =
  | 'pending_vote'
  | 'deadline_approaching'
  | 'missed'
  | 'reply'
  | 'join_request'
  | 'join_approved'
  | 'join_rejected'

export interface NotificationItem {
  id: string
  kind: NotificationKind
  sentAt: string
  readAt: string | null
  groupId: string
  groupName: string
  goalId: string | null
  goalHeader: string | null
  goalDescription: string | null
  postId: string | null
  replyText: string | null
  replierName: string | null
  joinRequestId: string | null
  joinRequestMessage: string | null
  requesterName: string | null
}
