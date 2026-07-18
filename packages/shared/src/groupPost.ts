import type { UserSummary } from './user'

export interface GroupPost {
  id: string
  text: string
  createdAt: string
  groupId: string
  authorId: string
  author: UserSummary
}
