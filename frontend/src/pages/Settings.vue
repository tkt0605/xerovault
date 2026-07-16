<template>
  <div class="mx-auto max-w-lg p-6">
    <h1 class="mb-6 font-serif text-2xl font-medium text-ink">設定</h1>

    <BaseCard class="mb-4">
      <h2 class="mb-3 font-semibold text-ink">プロフィール</h2>
      <div class="mb-4 flex items-center gap-3">
        <Avatar :name="form.name || authStore.user?.email || '?'" :size="48" />
        <p class="text-xs text-ink-faint">
          アバターは名前から自動生成されます（画像アップロードには対応していません）
        </p>
      </div>
      <form class="flex gap-2" @submit.prevent="handleSaveName">
        <BaseInput v-model="form.name" placeholder="名前" class="flex-1" />
        <BaseButton type="submit" :disabled="savingName">
          {{ savingName ? '保存中...' : '保存' }}
        </BaseButton>
      </form>
    </BaseCard>

    <BaseCard>
      <h2 class="mb-1 font-semibold text-ink">通知</h2>
      <p class="mb-3 text-xs text-ink-faint">
        投票待ち・締切間近・期限切れをまとめたメールを1日1回届けます。
      </p>
      <label class="flex cursor-pointer items-center justify-between gap-3">
        <span class="text-sm text-ink">通知メールを受け取る</span>
        <input
          v-model="form.notificationsEnabled"
          type="checkbox"
          class="h-5 w-5 accent-accent"
          :disabled="savingNotifications"
          @change="handleToggleNotifications"
        />
      </label>
    </BaseCard>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import Avatar from '@/components/ui/Avatar.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseInput from '@/components/ui/BaseInput.vue'
import BaseButton from '@/components/ui/BaseButton.vue'

const authStore = useAuthStore()

const form = ref({ name: '', notificationsEnabled: true })
const savingName = ref(false)
const savingNotifications = ref(false)

onMounted(async () => {
  if (!authStore.user) return
  form.value.name = authStore.user.name ?? ''

  const { data, error } = await supabase
    .from('profiles')
    .select('notifications_enabled')
    .eq('id', authStore.user.id)
    .single()
  if (!error && data) form.value.notificationsEnabled = data.notifications_enabled
})

async function handleSaveName() {
  if (!authStore.user) return
  savingName.value = true
  try {
    const { error } = await supabase
      .from('profiles')
      .update({ name: form.value.name || null })
      .eq('id', authStore.user.id)
    if (error) throw new Error(error.message)
    await authStore.fetchProfile(authStore.user.id)
  } finally {
    savingName.value = false
  }
}

async function handleToggleNotifications() {
  if (!authStore.user) return
  savingNotifications.value = true
  try {
    const { error } = await supabase
      .from('profiles')
      .update({ notifications_enabled: form.value.notificationsEnabled })
      .eq('id', authStore.user.id)
    if (error) throw new Error(error.message)
  } finally {
    savingNotifications.value = false
  }
}
</script>
