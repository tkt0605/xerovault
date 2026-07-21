<template>
  <div class="flex min-h-screen items-center justify-center bg-paper p-4">
    <BaseCard class="w-full max-w-sm p-8 text-center shadow-raised">
      <p v-if="loading" class="text-ink-soft">読み込み中...</p>
      <template v-else-if="error">
        <p class="mb-4 font-medium text-bad">{{ error }}</p>
        <RouterLink to="/" class="text-sm text-accent hover:underline">ホームへ戻る</RouterLink>
      </template>
      <template v-else-if="status === 'approved'">
        <div
          class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-good-soft"
        >
          <Icon name="check" :size="22" class="text-good" />
        </div>
        <p class="mb-1 text-lg font-semibold text-ink">参加が承認されています</p>
        <p class="mb-6 text-sm text-ink-soft">{{ target?.name }}</p>
        <RouterLink :to="`/group/${route.params.id}`">
          <BaseButton>グループを開く</BaseButton>
        </RouterLink>
      </template>
      <template v-else-if="status === 'pending'">
        <p class="mb-1 text-lg font-semibold text-ink">申請を送信済みです</p>
        <p class="text-sm text-ink-soft">{{ target?.name }}のオーナーの承認をお待ちください</p>
      </template>
      <template v-else-if="status === 'rejected'">
        <p class="mb-1 text-lg font-semibold text-ink">今回は見送られました</p>
        <p class="text-sm text-ink-soft">{{ target?.name }}への参加申請は承認されませんでした</p>
      </template>
      <template v-else-if="submitted">
        <div
          class="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-good-soft"
        >
          <Icon name="check" :size="22" class="text-good" />
        </div>
        <p class="mb-1 text-lg font-semibold text-ink">申請を送信しました</p>
        <p class="text-sm text-ink-soft">オーナーの承認をお待ちください</p>
      </template>
      <template v-else>
        <p class="mb-1 font-serif text-lg font-medium text-ink">{{ target?.name }}</p>
        <p v-if="target?.description" class="mb-4 text-sm text-ink-soft">
          {{ target.description }}
        </p>
        <p v-if="target?.tags.length" class="mb-4 text-sm text-ink-soft">
          {{ target.tags.map((t) => `#${t}`).join(' ') }}
        </p>
        <form class="space-y-3 text-left" @submit.prevent="handleSubmit">
          <BaseTextarea
            v-model="message"
            placeholder="自己紹介や参加したい理由(任意・200文字まで)"
            rows="3"
            maxlength="200"
          />
          <BaseButton type="submit" :disabled="submitting" class="w-full justify-center">
            {{ submitting ? '送信中...' : '参加をリクエストする' }}
          </BaseButton>
        </form>
      </template>
    </BaseCard>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { JoinRequestTarget } from '@xerovault/shared'
import { useGroupStore } from '@/stores/group'
import { useAuthStore } from '@/stores/auth'
import Icon from '@/components/ui/Icon.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseButton from '@/components/ui/BaseButton.vue'
import BaseTextarea from '@/components/ui/BaseTextarea.vue'

const route = useRoute()
const router = useRouter()
const groupStore = useGroupStore()
const auth = useAuthStore()

const loading = ref(true)
const error = ref('')
const target = ref<JoinRequestTarget | null>(null)
const status = ref<'pending' | 'approved' | 'rejected' | null>(null)
const message = ref('')
const submitting = ref(false)
const submitted = ref(false)

onMounted(async () => {
  await auth.restoreSession()
  if (!auth.isAuthenticated) {
    router.push(`/auth/login?redirect=${route.fullPath}`)
    return
  }
  try {
    target.value = await groupStore.fetchJoinRequestTarget(route.params.id as string)
    status.value = target.value.myRequestStatus
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'グループが見つかりませんでした'
  } finally {
    loading.value = false
  }
})

async function handleSubmit() {
  submitting.value = true
  try {
    await groupStore.createJoinRequest(route.params.id as string, message.value)
    submitted.value = true
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : '申請に失敗しました'
  } finally {
    submitting.value = false
  }
}
</script>
