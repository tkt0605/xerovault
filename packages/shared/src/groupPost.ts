import type { UserSummary } from './user'

// スレッド一覧の1件(ルート投稿+メタ情報)
export interface GroupThread {
  id: string
  text: string
  createdAt: string
  groupId: string
  authorId: string
  author: UserSummary
  replyCount: number
  lastMessageAt: string
}

// スレッド内の個々のメッセージ(ルート投稿・返信を問わず同じ形)
export interface ThreadMessage {
  id: string
  text: string
  createdAt: string
  groupId: string
  authorId: string
  author: UserSummary
}
