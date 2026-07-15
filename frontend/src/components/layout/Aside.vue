<template>
  <aside
    class="w-64 shrink-0 border-r border-zinc-200 dark:border-zinc-800 bg-zinc-50 dark:bg-zinc-900 flex flex-col h-screen overflow-y-auto"
  >
    <div class="p-4 border-b border-zinc-200 dark:border-zinc-800">
      <div class="flex items-center gap-2">
        <img :src="auth.user?.avatar ?? defaultAvatar" class="w-8 h-8 rounded-full object-cover" />
        <span class="text-sm font-medium truncate">{{ auth.user?.email }}</span>
      </div>
    </div>

    <nav class="flex-1 p-3 space-y-1">
      <p class="text-xs font-semibold text-zinc-400 uppercase tracking-wider px-2 mb-2">グループ</p>
      <RouterLink
        v-for="g in groupStore.groups"
        :key="g.id"
        :to="`/group/${g.id}`"
        class="flex items-center gap-2 px-3 py-2 rounded-lg text-sm transition hover:bg-zinc-100 dark:hover:bg-zinc-800"
        :class="{ 'bg-brand-50 text-brand-600 dark:bg-zinc-800': route.params.id === g.id }"
      >
        <span class="truncate">{{ g.name }}</span>
        <span class="ml-auto text-xs font-bold text-brand-500">{{ g.score }}</span>
      </RouterLink>
    </nav>

    <div class="p-3 border-t border-zinc-200 dark:border-zinc-800">
      <button
        class="w-full py-2 rounded-lg text-sm font-medium bg-brand-500 hover:bg-brand-600 text-white transition"
        @click="showCreateDialog = true"
      >
        ＋ グループ作成
      </button>
    </div>

    <!-- グループ作成ダイアログ -->
    <Teleport to="body">
      <div
        v-if="showCreateDialog"
        class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
      >
        <div class="bg-white dark:bg-zinc-900 rounded-2xl p-6 w-full max-w-md shadow-2xl">
          <h2 class="text-lg font-bold mb-4">グループを作成</h2>
          <form class="space-y-3" @submit.prevent="handleCreate">
            <input
              v-model="form.name"
              type="text"
              placeholder="グループ名 *"
              required
              class="w-full px-4 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <input
              v-model="form.tag"
              type="text"
              placeholder="タグ（任意）"
              class="w-full px-4 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500"
            />
            <label class="flex items-center gap-2 text-sm cursor-pointer">
              <input v-model="form.isPublic" type="checkbox" class="rounded" />
              ランキングに公開する
            </label>
            <div class="flex gap-2 pt-2">
              <button
                type="button"
                class="flex-1 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 text-sm transition hover:bg-zinc-50 dark:hover:bg-zinc-800"
                @click="showCreateDialog = false"
              >
                キャンセル
              </button>
              <button
                type="submit"
                :disabled="creating"
                class="flex-1 py-2 rounded-xl bg-brand-500 text-white text-sm font-medium transition hover:bg-brand-600 disabled:opacity-50"
              >
                {{ creating ? '作成中...' : '作成' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </aside>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useGroupStore } from '@/stores/group'

const auth = useAuthStore()
const groupStore = useGroupStore()
const route = useRoute()
const router = useRouter()
const showCreateDialog = ref(false)
const creating = ref(false)
const form = ref({ name: '', tag: '', isPublic: false })
const defaultAvatar = `https://api.dicebear.com/9.x/identicon/svg?seed=default`

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
