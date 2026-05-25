import { defineStore } from 'pinia'
import { ref } from 'vue'
import { api } from '@/api/client'

export interface Message {
  id: string
  text: string
  createdAt: string
  goalId: string
  author: { id: string; email: string; avatar: string | null }
}

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
