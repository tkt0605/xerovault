import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Message } from '@xerovault/shared'
import { rpc } from '@/lib/rpc'

export type { Message }

export const useMessageStore = defineStore('message', () => {
  const messages = ref<Message[]>([])

  async function fetchMessages(goalId: string): Promise<Message[]> {
    messages.value = await rpc<Message[]>('get_messages', { p_goal_id: goalId })
    return messages.value
  }

  async function sendMessage(goalId: string, text: string): Promise<Message> {
    const msg = await rpc<Message>('send_message', { p_goal_id: goalId, p_text: text })
    messages.value.push(msg)
    return msg
  }

  return { messages, fetchMessages, sendMessage }
})
