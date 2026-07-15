<template>
  <aside
    class="flex h-screen w-64 shrink-0 flex-col overflow-y-auto border-r border-line bg-paper-sunken"
  >
    <div class="border-b border-line p-4">
      <div class="flex items-center gap-2.5">
        <Avatar :name="auth.user?.name ?? auth.user?.email ?? '?'" :size="32" />
        <span class="truncate text-sm font-medium text-ink">{{
          auth.user?.name ?? auth.user?.email
        }}</span>
      </div>
    </div>

    <nav class="flex-1 space-y-1 p-3">
      <p class="mb-2 px-2 text-xs font-semibold uppercase tracking-wider text-ink-faint">
        グループ
      </p>
      <RouterLink
        v-for="g in groupStore.groups"
        :key="g.id"
        :to="`/group/${g.id}`"
        class="flex items-center gap-2 rounded-control px-3 py-2 text-sm text-ink-soft transition-colors hover:bg-paper-raised hover:text-ink"
        :class="{ 'bg-paper-raised text-ink shadow-card': route.params.id === g.id }"
      >
        <span class="truncate">{{ g.name }}</span>
        <span class="ml-auto text-xs font-semibold text-accent-strong">{{ g.score }}</span>
      </RouterLink>
    </nav>

    <div class="border-t border-line p-3">
      <BaseButton class="w-full justify-center" @click="showCreateDialog = true">
        <Icon name="plus" :size="14" />
        グループ作成
      </BaseButton>
    </div>

    <!-- グループ作成ダイアログ -->
    <Teleport to="body">
      <div
        v-if="showCreateDialog"
        class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40"
      >
        <BaseCard class="w-full max-w-md shadow-modal">
          <h2 class="mb-4 font-serif text-lg font-medium text-ink">グループを作成</h2>
          <form class="space-y-3" @submit.prevent="handleCreate">
            <BaseInput v-model="form.name" placeholder="グループ名 *" required />
            <BaseInput v-model="form.tag" placeholder="タグ（任意）" />
            <label class="flex cursor-pointer items-center gap-2 text-sm text-ink-soft">
              <input v-model="form.isPublic" type="checkbox" class="rounded" />
              ランキングに公開する
            </label>
            <div class="flex gap-2 pt-2">
              <BaseButton
                type="button"
                variant="ghost"
                class="flex-1 justify-center"
                @click="showCreateDialog = false"
              >
                キャンセル
              </BaseButton>
              <BaseButton type="submit" :disabled="creating" class="flex-1 justify-center">
                {{ creating ? '作成中...' : '作成' }}
              </BaseButton>
            </div>
          </form>
        </BaseCard>
      </div>
    </Teleport>
  </aside>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useGroupStore } from '@/stores/group'
import Avatar from '@/components/ui/Avatar.vue'
import Icon from '@/components/ui/Icon.vue'
import BaseButton from '@/components/ui/BaseButton.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseInput from '@/components/ui/BaseInput.vue'

const auth = useAuthStore()
const groupStore = useGroupStore()
const route = useRoute()
const router = useRouter()
const showCreateDialog = ref(false)
const creating = ref(false)
const form = ref({ name: '', tag: '', isPublic: false })

onMounted(() => groupStore.fetchMyGroups())

async function handleCreate() {
  creating.value = true
  try {
    const g = await groupStore.createGroup(form.value)
    showCreateDialog.value = false
    form.value = { name: '', tag: '', isPublic: false }
    router.push(`/group/${g.id}`)
  } finally {
    creating.value = false
  }
}
</script>
