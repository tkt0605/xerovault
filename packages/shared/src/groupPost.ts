import type { UserSummary } from './user'

export interface GroupPost {
  id: string
  text: string
  createdAt: string
  groupId: string
  authorId: string
  parentPostId: string | null
  author: UserSummary
  replies: GroupPost[]
}
