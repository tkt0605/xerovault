<template>
  <header
    class="sticky top-0 z-10 bg-white dark:bg-zinc-900 border-b border-zinc-200 dark:border-zinc-800 px-6 py-3 flex items-center justify-between"
  >
    <RouterLink to="/" class="font-bold text-lg tracking-tight text-zinc-900 dark:text-white">
      Xerovault
    </RouterLink>
    <div class="flex items-center gap-3">
      <RouterLink
        to="/ranking"
        class="text-sm text-zinc-500 hover:text-zinc-900 dark:hover:text-white transition"
      >
        ランキング
      </RouterLink>
      <button
        v-if="auth.isAuthenticated"
        class="text-sm text-zinc-500 hover:text-red-500 transition"
        @click="handleLogout"
      >
        ログアウト
      </button>
    </div>
  </header>
</template>

<script setup lang="ts">
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const auth = useAuthStore()
const router = useRouter()

async function handleLogout() {
  await auth.logout()
  router.push('/auth/login')
}
</script>
