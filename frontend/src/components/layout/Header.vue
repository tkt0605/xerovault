<template>
  <header
    class="sticky top-0 z-10 flex items-center justify-between border-b border-line bg-paper-raised px-6 py-3"
  >
    <!-- <RouterLink to="/" class="font-serif text-lg font-medium tracking-tight text-ink">
      Xerovault
    </RouterLink> -->
    <div>
      <button
        class="flex items-center justify-center rounded-control p-1.5 text-ink-soft transition-colors hover:bg-paper-sunken hover:text-ink"
        aria-label="サイドバーの表示切り替え"
        @click="ui.toggleAside()"
      >
        <Icon name="menu" :size="18" />
      </button>
    </div>
    <div class="flex items-center gap-4">
      <div v-if="auth.isAuthenticated" class="relative">
        <button
          class="relative flex items-center justify-center rounded-control p-1.5 text-ink-soft transition-colors hover:bg-paper-sunken hover:text-ink"
          aria-label="通知"
          @click="toggleNotifications"
        >
          <Icon name="bell" :size="18" />
          <span
            v-if="notification.unreadCount > 0"
            class="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-bad px-1 text-[10px] font-semibold text-paper-raised"
          >
            {{ notification.unreadCount > 9 ? '9+' : notification.unreadCount }}
          </span>
        </button>
        <div
          v-if="showNotifications"
          class="absolute right-0 top-full z-20 mt-2 w-80 rounded-surface border border-line bg-paper-raised p-2 text-left shadow-card"
        >
          <p v-if="!notification.items.length" class="p-3 text-center text-xs text-ink-faint">
            通知はありません
          </p>
          <button
            v-for="n in notification.items"
            :key="n.id"
            class="flex w-full flex-col items-start gap-0.5 rounded-control p-2 text-left transition-colors hover:bg-paper-sunken"
            @click="goToNotification(n)"
          >
            <span class="text-xs font-semibold text-ink-soft">{{ KIND_LABEL[n.kind] }}</span>
            <span class="truncate text-sm text-ink">
              [{{ n.groupName }}] {{ n.goalHeader || n.goalDescription }}
            </span>
            <span class="text-[11px] text-ink-faint">{{ formatDate(n.sentAt) }}</span>
          </button>
        </div>
      </div>
      <button
        v-if="auth.isAuthenticated"
        class="flex items-center gap-1.5 text-sm text-ink-soft transition-colors hover:text-bad"
        @click="handleLogout"
      >
        <Icon name="logout" :size="14" />
        ログアウト
      </button>
    </div>
  </header>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import type { NotificationItem, NotificationKind } from '@xerovault/shared'
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { useNotificationStore } from '@/stores/notification'
import { useNotificationEvents } from '@/composables/useNotificationEvents'
import Icon from '@/components/ui/Icon.vue'

const auth = useAuthStore()
const ui = useUiStore()
const notification = useNotificationStore()
const router = useRouter()

const showNotifications = ref(false)

const KIND_LABEL: Record<NotificationKind, string> = {
  pending_vote: '投票のお願い',
  deadline_approaching: '締切間近',
  missed: '期限切れ',
}

onMounted(() => {
  if (!auth.user) return
  notification.fetchUnreadCount()
  useNotificationEvents(auth.user.id, () => notification.incrementUnread())
})

async function toggleNotifications() {
  showNotifications.value = !showNotifications.value
  if (showNotifications.value) {
    await notification.fetchNotifications()
    await notification.markAllRead()
  }
}

function goToNotification(n: NotificationItem) {
  showNotifications.value = false
  router.push(`/group/${n.groupId}/goal/${n.goalId}`)
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' })
}

async function handleLogout() {
  await auth.logout()
  router.push('/auth/login')
}
</script>
