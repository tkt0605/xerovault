<template>
  <div
    v-if="ui.asideOpen"
    class="fixed inset-0 z-30 bg-ink/40 md:hidden"
    @click="ui.toggleAside()"
  />

  <div
    class="fixed inset-y-0 left-0 z-40 h-screen w-64 shrink-0 overflow-hidden transition-transform duration-[400ms] ease-in-out md:static md:z-auto md:transition-[width] md:duration-[600ms]"
    :class="ui.asideOpen ? 'translate-x-0 md:w-64' : '-translate-x-full md:w-0 md:translate-x-0'"
  >
    <aside class="flex h-screen w-64 flex-col overflow-y-auto border-r border-line bg-paper-sunken">
      <div class="border-b border-line p-3">
        <div class="flex items-center gap-3">
          <span class="font-serif text-lg font-medium tracking-tight text-ink">Xerovault</span>
        </div>
      </div>
      <nav class="flex-1 space-y-1 p-3">
        <RouterLink
          to="/"
          class="flex items-center gap-2.5 rounded-control px-3 py-2 text-sm font-medium text-ink-soft transition-colors hover:bg-paper-raised hover:text-ink"
          :class="{ 'bg-paper-raised text-ink shadow-card': route.path === '/' }"
          @click="ui.closeAsideOnMobile()"
        >
          <Icon name="home" :size="15" />
          ホーム
        </RouterLink>
        <RouterLink
          to="/ranking"
          class="flex items-center gap-2.5 rounded-control px-3 py-2 text-sm font-medium text-ink-soft transition-colors hover:bg-paper-raised hover:text-ink"
          :class="{ 'bg-paper-raised text-ink shadow-card': route.path === '/ranking' }"
          @click="ui.closeAsideOnMobile()"
        >
          <Icon name="ranking" :size="15" />
          ランキング
        </RouterLink>
        <button
          class="flex w-full items-center gap-2.5 rounded-control px-3 py-2 text-sm font-medium text-ink-soft transition-colors hover:bg-paper-raised hover:text-ink"
          @click="openCreateDialog"
        >
          <Icon name="plus" :size="15" />
          グループ作成
        </button>

        <p class="mb-2 mt-4 px-2 text-xs font-semibold uppercase tracking-wider text-ink-faint">
          グループ一覧
        </p>
        <RouterLink
          v-for="g in groupStore.groups"
          :key="g.id"
          :to="`/group/${g.id}`"
          class="flex items-center gap-2 rounded-control px-3 py-2 text-sm text-ink-soft transition-colors hover:bg-paper-raised hover:text-ink"
          :class="{ 'bg-paper-raised text-ink shadow-card': route.params.id === g.id }"
          @click="ui.closeAsideOnMobile()"
        >
          <span class="truncate">{{ g.name }}</span>
          <span class="ml-auto text-xs font-semibold text-accent-strong">{{ g.score }}</span>
        </RouterLink>
      </nav>

      <!-- グループ作成ダイアログ -->
      <Teleport to="body">
        <div
          v-if="showCreateDialog"
          class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4"
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
      <div class="border-b border-line p-4">
        <div class="flex items-center gap-2.5">
          <Avatar :name="auth.user?.name ?? auth.user?.email ?? '?'" :size="32" />
          <span class="truncate text-sm font-medium text-ink">{{
            auth.user?.name ?? auth.user?.email
          }}</span>
        </div>
      </div>
    </aside>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useGroupStore } from '@/stores/group'
import { useUiStore } from '@/stores/ui'
import Avatar from '@/components/ui/Avatar.vue'
import Icon from '@/components/ui/Icon.vue'
import BaseButton from '@/components/ui/BaseButton.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseInput from '@/components/ui/BaseInput.vue'

const auth = useAuthStore()
const ui = useUiStore()
const groupStore = useGroupStore()
const route = useRoute()
const router = useRouter()
const showCreateDialog = ref(false)
const creating = ref(false)
const form = ref({ name: '', tag: '', isPublic: false })

onMounted(() => groupStore.fetchMyGroups())

function openCreateDialog() {
  showCreateDialog.value = true
  ui.closeAsideOnMobile()
}

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
