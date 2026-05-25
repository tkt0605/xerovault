<template>
  <div class="p-6 max-w-3xl mx-auto">
    <div v-if="!group" class="text-center py-16 text-zinc-400">読み込み中...</div>
    <template v-else>
      <!-- ヘッダー -->
      <div class="mb-6">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">{{ group.name }}</h1>
            <p v-if="group.tag" class="text-sm text-zinc-500 mt-0.5">#{{ group.tag }}</p>
          </div>
          <div class="text-right shrink-0">
            <p class="text-3xl font-extrabold text-brand-500">{{ group.score }}</p>
            <p class="text-xs text-zinc-400">スコア</p>
            <p v-if="group.streak >= 3" class="text-xs text-orange-500 font-medium mt-0.5">🔥{{ group.streak }}連続達成</p>
          </div>
        </div>
        <div class="flex items-center gap-3 mt-4 flex-wrap">
          <div class="flex -space-x-2">
            <img v-for="m in group.members.slice(0, 5)" :key="m.id"
              :src="m.avatar ?? defaultAvatar"
              class="w-8 h-8 rounded-full ring-2 ring-white dark:ring-zinc-900 object-cover" />
          </div>
          <span class="text-sm text-zinc-500">{{ group.members.length }}人のメンバー</span>
          <button @click="handleInvite"
            class="ml-auto text-sm px-4 py-1.5 rounded-full border border-brand-500 text-brand-500 hover:bg-brand-500 hover:text-white transition">
            招待リンク作成
          </button>
        </div>
        <div v-if="inviteUrl" class="mt-3 p-3 bg-zinc-100 dark:bg-zinc-800 rounded-xl text-xs break-all text-zinc-600 dark:text-zinc-300">
          {{ inviteUrl }}
          <button @click="copyInvite" class="ml-2 text-brand-500 hover:underline">コピー</button>
        </div>
      </div>

      <!-- ゴール一覧 -->
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-semibold text-zinc-900 dark:text-white">ゴール一覧</h2>
        <button @click="showAddGoal = true"
          class="text-sm px-4 py-1.5 rounded-full bg-brand-500 text-white hover:bg-brand-600 transition">
          ＋ ゴール追加
        </button>
      </div>

      <div v-if="!goalStore.goals.length" class="text-center py-12 text-zinc-400">
        <p class="text-3xl mb-3">🎯</p>
        <p class="font-medium">ゴールがまだありません</p>
      </div>
      <div v-else class="space-y-3">
        <GoalCard
          v-for="g in goalStore.goals"
          :key="g.id"
          :goal="g"
          @click="router.push(`/studio/${group.id}/goal/${g.id}`)" />
      </div>
    </template>

    <!-- ゴール追加ダイアログ -->
    <Teleport to="body">
      <div v-if="showAddGoal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
        <div class="bg-white dark:bg-zinc-900 rounded-2xl p-6 w-full max-w-md shadow-2xl">
          <h2 class="text-lg font-bold mb-4">ゴールを追加</h2>
          <form @submit.prevent="handleAddGoal" class="space-y-3">
            <input v-model="goalForm.header" type="text" placeholder="タイトル（任意）"
              class="w-full px-4 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500" />
            <textarea v-model="goalForm.description" placeholder="ゴールの内容 *" required rows="3"
              class="w-full px-4 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none" />
            <input v-model="goalForm.deadline" type="datetime-local"
              class="w-full px-4 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500" />
            <div class="flex gap-2 pt-2">
              <button type="button" @click="showAddGoal = false"
                class="flex-1 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 text-sm transition hover:bg-zinc-50 dark:hover:bg-zinc-800">
                キャンセル
              </button>
              <button type="submit" :disabled="addingGoal"
                class="flex-1 py-2 rounded-xl bg-brand-500 text-white text-sm font-medium transition hover:bg-brand-600 disabled:opacity-50">
                {{ addingGoal ? '追加中...' : '追加' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useGroupStore } from '@/stores/group'
import { useGoalStore } from '@/stores/goal'
import GoalCard from '@/components/goal/GoalCard.vue'

const route = useRoute()
const router = useRouter()
const groupStore = useGroupStore()
const goalStore = useGoalStore()
const group = ref(groupStore.current)
const inviteUrl = ref('')
const showAddGoal = ref(false)
const addingGoal = ref(false)
const goalForm = ref({ header: '', description: '', deadline: '' })
const defaultAvatar = `https://api.dicebear.com/9.x/identicon/svg?seed=default`

onMounted(async () => {
  const id = route.params.id as string
  group.value = await groupStore.fetchGroup(id)
  await goalStore.fetchGoals(id)
})

async function handleInvite() {
  const id = route.params.id as string
  inviteUrl.value = await groupStore.createInvite(id)
}

function copyInvite() {
  navigator.clipboard.writeText(inviteUrl.value)
}

async function handleAddGoal() {
  addingGoal.value = true
  try {
    await goalStore.createGoal(route.params.id as string, {
      ...goalForm.value,
      deadline: goalForm.value.deadline || null,
    })
    showAddGoal.value = false
    goalForm.value = { header: '', description: '', deadline: '' }
  } finally {
    addingGoal.value = false
  }
}
</script>
