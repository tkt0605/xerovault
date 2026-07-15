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

  // SSEで受信したメッセージを追加する(自分の送信分が二重にならないようIDで重複排除)
  function receiveMessage(message: Message): void {
    if (!messages.value.some((m) => m.id === message.id)) {
      messages.value.push(message)
    }
  }

  return { messages, fetchMessages, sendMessage, receiveMessage }
})
