<template>
  <div class="flex flex-col h-[calc(100vh-57px)]">
    <div v-if="!goal" class="flex-1 flex items-center justify-center text-zinc-400">
      読み込み中...
    </div>
    <template v-else>
      <!-- ヘッダー -->
      <header
        class="shrink-0 bg-gradient-to-r from-zinc-900 to-zinc-800 text-white px-6 py-4 flex items-center gap-4"
      >
        <button
          class="text-zinc-400 hover:text-white transition"
          @click="router.push(`/group/${goal.group?.id}`)"
        >
          ← {{ goal.group?.name ?? 'グループへ' }}
        </button>
        <div class="flex-1 min-w-0">
          <h1 class="font-bold truncate">{{ goal.header || goal.description }}</h1>
          <p v-if="goal.deadline" class="text-xs text-zinc-400">
            締切: {{ formatDate(goal.deadline) }}
          </p>
        </div>
        <span
          v-if="goal.isCompleted"
          class="shrink-0 text-xs px-3 py-1 rounded-full bg-green-500 text-white font-medium"
          >達成済み</span
        >
      </header>

      <!-- 投票パネル -->
      <div
        class="shrink-0 border-b border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900 px-6 py-4"
      >
        <div class="flex items-center gap-4">
          <div class="flex-1">
            <div class="flex items-center justify-between text-sm mb-1">
              <span class="text-zinc-600 dark:text-zinc-400">達成投票</span>
              <span
                class="font-bold"
                :class="
                  (voteStore.status?.progress ?? 0 >= 90)
                    ? 'text-green-500'
                    : 'text-zinc-900 dark:text-white'
                "
              >
                {{ voteStore.status?.progress ?? 0 }}%
              </span>
            </div>
            <div class="h-3 rounded-full bg-zinc-100 dark:bg-zinc-700 overflow-hidden">
              <div
                class="h-full rounded-full transition-all duration-700"
                :class="progressBarClass"
                :style="{ width: `${voteStore.status?.progress ?? 0}%` }"
              />
            </div>
            <p class="text-xs text-zinc-400 mt-1">
              {{ voteStore.status?.totalMembers ?? 0 }}人中 {{ yesCount }}人が賛成
            </p>
          </div>
          <div v-if="!goal.isCompleted" class="flex gap-2 shrink-0">
            <button
              :class="
                voteStore.status?.myVote === true
                  ? 'bg-green-500 text-white'
                  : 'border border-green-500 text-green-500 hover:bg-green-50 dark:hover:bg-green-900/20'
              "
              class="px-4 py-2 rounded-xl text-sm font-medium transition"
              @click="vote(true)"
            >
              YES 👍
            </button>
            <button
              :class="
                voteStore.status?.myVote === false
                  ? 'bg-red-500 text-white'
                  : 'border border-red-400 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20'
              "
              class="px-4 py-2 rounded-xl text-sm font-medium transition"
              @click="vote(false)"
            >
              NO 👎
            </button>
          </div>
        </div>

        <!-- 投票メンバー一覧 -->
        <div class="flex gap-2 mt-3 flex-wrap">
          <div
            v-for="v in voteStore.status?.votes"
            :key="v.voter.id"
            class="flex items-center gap-1"
          >
            <img :src="v.voter.avatar ?? defaultAvatar" class="w-6 h-6 rounded-full object-cover" />
            <span class="text-sm">{{
              v.isYes === true ? '✅' : v.isYes === false ? '❌' : '⏳'
            }}</span>
          </div>
        </div>
      </div>

      <!-- メッセージ -->
      <div ref="scrollArea" class="flex-1 overflow-y-auto p-4 space-y-3">
        <div v-for="msg in messageStore.messages" :key="msg.id" class="flex items-start gap-3">
          <img
            :src="msg.author.avatar ?? defaultAvatar"
            class="w-9 h-9 rounded-full object-cover shrink-0"
          />
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 mb-0.5">
              <span class="text-sm font-semibold text-zinc-900 dark:text-white">{{
                msg.author.name ?? msg.author.email
              }}</span>
              <span class="text-xs text-zinc-400">{{ formatDate(msg.createdAt) }}</span>
            </div>
            <p class="text-sm text-zinc-700 dark:text-zinc-300 whitespace-pre-wrap break-words">
              {{ msg.text }}
            </p>
          </div>
        </div>
      </div>

      <!-- 入力欄 -->
      <div
        class="shrink-0 border-t border-zinc-200 dark:border-zinc-800 p-3 bg-white dark:bg-zinc-900"
      >
        <form class="flex gap-2" @submit.prevent="handleSend">
          <textarea
            ref="textareaRef"
            v-model="newMessage"
            placeholder="メッセージを入力..."
            rows="1"
            class="flex-1 px-4 py-2 rounded-xl border border-zinc-300 dark:border-zinc-700 bg-transparent focus:outline-none focus:ring-2 focus:ring-brand-500 resize-none text-sm"
            @keydown.enter.exact.prevent="handleSend"
          />
          <button
            type="submit"
            :disabled="!newMessage.trim()"
            class="px-4 py-2 rounded-xl bg-brand-500 text-white text-sm font-medium disabled:opacity-40 hover:bg-brand-600 transition"
          >
            送信
          </button>
        </form>
      </div>
    </template>

    <!-- 達成モーダル -->
    <AchievementModal
      :show="showAchievement"
      :goal-header="goal?.header ?? goal?.description ?? ''"
      :points-earned="earnedPoints"
      @close="showAchievement = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useGoalStore } from '@/stores/goal'
import { useVoteStore } from '@/stores/vote'
import { useMessageStore } from '@/stores/message'
import AchievementModal from '@/components/vote/AchievementModal.vue'

const route = useRoute()
const router = useRouter()
const goalStore = useGoalStore()
const voteStore = useVoteStore()
const messageStore = useMessageStore()

const goal = ref(goalStore.current)
const newMessage = ref('')
const scrollArea = ref<HTMLElement | null>(null)
const showAchievement = ref(false)
const earnedPoints = ref(25)
const defaultAvatar = `https://api.dicebear.com/9.x/identicon/svg?seed=default`

const yesCount = computed(() => voteStore.status?.votes.filter((v) => v.isYes === true).length ?? 0)

const progressBarClass = computed(() => {
  const p = voteStore.status?.progress ?? 0
  if (p >= 90) return 'bg-green-500'
  if (p >= 50) return 'bg-yellow-500'
  return 'bg-red-400'
})

onMounted(async () => {
  const goalId = route.params.goalId as string
  goal.value = await goalStore.fetchGoal(goalId)
  await Promise.all([voteStore.fetchVoteStatus(goalId), messageStore.fetchMessages(goalId)])
  await nextTick()
  scrollToBottom()
})

watch(
  () => messageStore.messages.length,
  () => nextTick(scrollToBottom)
)

function scrollToBottom() {
  if (scrollArea.value) scrollArea.value.scrollTop = scrollArea.value.scrollHeight
}

async function vote(isYes: boolean) {
  const goalId = route.params.goalId as string
  if (voteStore.status?.myVote === isYes) {
    await voteStore.cancelVote(goalId)
    return
  }
  const result = await voteStore.castVote(goalId, isYes)
  if (result.justCompleted) {
    earnedPoints.value = goal.value?.isConcrete ? 25 : 5
    showAchievement.value = true
    goal.value = await goalStore.fetchGoal(goalId)
  }
}

async function handleSend() {
  const text = newMessage.value.trim()
  if (!text) return
  newMessage.value = ''
  await messageStore.sendMessage(route.params.goalId as string, text)
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' })
}
</script>
