<template>
  <div class="min-h-screen flex items-center justify-center p-4">
    <div class="bg-white dark:bg-zinc-900 rounded-2xl p-8 max-w-sm w-full shadow-lg text-center">
      <p v-if="loading" class="text-zinc-500">参加処理中...</p>
      <template v-else-if="error">
        <p class="text-red-500 font-medium mb-4">{{ error }}</p>
        <RouterLink to="/" class="text-brand-500 hover:underline text-sm">ホームへ戻る</RouterLink>
      </template>
      <template v-else-if="joined">
        <p class="text-2xl mb-3">🎉</p>
        <p class="font-bold text-lg mb-1">参加しました！</p>
        <p class="text-zinc-500 text-sm mb-6">{{ groupName }}</p>
        <RouterLink :to="`/studio/${route.params.id}`"
          class="px-6 py-2 rounded-full bg-brand-500 text-white text-sm hover:bg-brand-600 transition">
          スタジオを開く
        </RouterLink>
      </template>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useGroupStore } from '@/stores/group'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'

const route = useRoute()
const router = useRouter()
const groupStore = useGroupStore()
const auth = useAuthStore()

const loading = ref(true)
const error = ref('')
const joined = ref(false)
const groupName = ref('')

onMounted(async () => {
  await auth.restoreSession()
  if (!auth.isAuthenticated) {
    router.push(`/auth/login?redirect=${route.fullPath}`)
    return
  }
  const data = route.query.data as string
  if (!data) { error.value = '招待リンクが無効です'; loading.value = false; return }
  try {
    const g = await groupStore.joinGroup(route.params.id as string, data)
    groupName.value = g.name
    joined.value = true
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : '参加に失敗しました'
  } finally {
    loading.value = false
  }
})
</script>
