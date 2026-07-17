import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { NotificationItem } from '@xerovault/shared'
import { rpc } from '@/lib/rpc'

export const useNotificationStore = defineStore('notification', () => {
  const items = ref<NotificationItem[]>([])
  const unreadCount = ref(0)

  async function fetchUnreadCount(): Promise<void> {
    unreadCount.value = await rpc<number>('get_unread_notification_count')
  }

  async function fetchNotifications(): Promise<void> {
    items.value = await rpc<NotificationItem[]>('get_my_notifications')
  }

  async function markAllRead(): Promise<void> {
    if (unreadCount.value === 0) return
    await rpc('mark_notifications_read')
    items.value = items.value.map((n) => ({ ...n, readAt: n.readAt ?? new Date().toISOString() }))
    unreadCount.value = 0
  }

  async function markRead(id: string): Promise<void> {
    const target = items.value.find((n) => n.id === id)
    if (!target || target.readAt) return
    await rpc('mark_notifications_read', { p_ids: [id] })
    target.readAt = new Date().toISOString()
    unreadCount.value = Math.max(0, unreadCount.value - 1)
  }

  function incrementUnread(): void {
    unreadCount.value++
  }

  return {
    items,
    unreadCount,
    fetchUnreadCount,
    fetchNotifications,
    markAllRead,
    markRead,
    incrementUnread,
  }
})
