<template>
  <header
    class="sticky top-0 z-10 flex items-center justify-between border-b border-line bg-paper-raised px-6 py-3"
  >
    <RouterLink to="/" class="font-serif text-lg font-medium tracking-tight text-ink">
      Xerovault
    </RouterLink>
    <div class="flex items-center gap-4">
      <RouterLink to="/ranking" class="text-sm text-ink-soft transition-colors hover:text-ink">
        ランキング
      </RouterLink>
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
import { useRouter } from 'vue-router'
import Icon from '@/components/ui/Icon.vue'

const auth = useAuthStore()
const router = useRouter()

async function handleLogout() {
  await auth.logout()
  router.push('/auth/login')
}
</script>
