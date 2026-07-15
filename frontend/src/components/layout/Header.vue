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
import { useAuthStore } from '@/stores/auth'
import { useUiStore } from '@/stores/ui'
import { useRouter } from 'vue-router'
import Icon from '@/components/ui/Icon.vue'

const auth = useAuthStore()
const ui = useUiStore()
const router = useRouter()

async function handleLogout() {
  await auth.logout()
  router.push('/auth/login')
}
</script>
