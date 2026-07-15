<template>
  <div class="flex min-h-screen items-center justify-center bg-paper p-4">
    <BaseCard class="w-full max-w-sm p-8 text-center shadow-raised">
      <p v-if="loading" class="text-ink-soft">参加処理中...</p>
      <template v-else-if="error">
        <p class="mb-4 font-medium text-bad">{{ error }}</p>
        <RouterLink to="/" class="text-sm text-accent hover:underline">ホームへ戻る</RouterLink>
      </template>
      <template v-else-if="joined">
        <div
          class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-good-soft"
        >
          <Icon name="check" :size="22" class="text-good" />
        </div>
        <p class="mb-1 text-lg font-semibold text-ink">参加しました</p>
        <p class="mb-6 text-sm text-ink-soft">{{ groupName }}</p>
        <RouterLink :to="`/group/${route.params.id}`">
          <BaseButton>グループを開く</BaseButton>
        </RouterLink>
      </template>
    </BaseCard>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useGroupStore } from '@/stores/group'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import Icon from '@/components/ui/Icon.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseButton from '@/components/ui/BaseButton.vue'

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
  if (!data) {
    error.value = '招待リンクが無効です'
    loading.value = false
    return
  }
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
