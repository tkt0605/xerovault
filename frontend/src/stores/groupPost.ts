import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { GroupThread, ThreadMessage } from '@sodalis/shared'
import { rpc } from '@/lib/rpc'

export const useGroupPostStore = defineStore('groupPost', () => {
  const threads = ref<GroupThread[]>([])
  const messages = ref<ThreadMessage[]>([])

  async function fetchThreads(groupId: string): Promise<GroupThread[]> {
    threads.value = await rpc<GroupThread[]>('get_group_posts', { p_group_id: groupId })
    return threads.value
  }

  async function createThread(groupId: string, text: string): Promise<ThreadMessage> {
    const thread = await rpc<ThreadMessage>('create_group_post', {
      p_group_id: groupId,
      p_text: text,
    })
    threads.value.unshift({ ...thread, replyCount: 0, lastMessageAt: thread.createdAt })
    return thread
  }

  async function fetchMessages(threadId: string): Promise<ThreadMessage[]> {
    messages.value = await rpc<ThreadMessage[]>('get_thread_messages', { p_post_id: threadId })
    return messages.value
  }

  async function sendMessage(
    groupId: string,
    threadId: string,
    text: string
  ): Promise<ThreadMessage> {
    const message = await rpc<ThreadMessage>('create_group_post', {
      p_group_id: groupId,
      p_text: text,
      p_parent_post_id: threadId,
    })
    messages.value.push(message)
    return message
  }

  return { threads, messages, fetchThreads, createThread, fetchMessages, sendMessage }
})
