import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { Message } from '@xerovault/shared'
import { api } from '@/api/client'

export type { Message }

export const useMessageStore = defineStore('message', () => {
  const messages = ref<Message[]>([])

  async function fetchMessages(goalId: string): Promise<Message[]> {
    messages.value = await api.get<Message[]>(`/goals/${goalId}/messages`)
    return messages.value
  }

  async function sendMessage(goalId: string, text: string): Promise<Message> {
    const msg = await api.post<Message>(`/goals/${goalId}/messages`, { text })
    messages.value.push(msg)
    return msg
  }

  return { messages, fetchMessages, sendMessage }
})
