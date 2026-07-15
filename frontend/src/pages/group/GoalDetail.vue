<template>
  <div class="flex h-[calc(100vh-57px)] flex-col">
    <div v-if="!goal" class="flex flex-1 items-center justify-center text-ink-faint">
      読み込み中...
    </div>
    <template v-else>
      <!-- ヘッダー -->
      <header class="flex shrink-0 items-center gap-4 bg-ink px-6 py-4 text-paper">
        <button
          class="flex items-center gap-1 text-ink-faint transition-colors hover:text-paper"
          @click="router.push(`/group/${goal.group?.id}`)"
        >
          <Icon name="chevron-left" :size="16" />
          {{ goal.group?.name ?? 'グループへ' }}
        </button>
        <div class="min-w-0 flex-1">
          <h1 class="truncate font-serif font-medium">{{ goal.header || goal.description }}</h1>
          <p v-if="goal.deadline" class="text-xs text-ink-faint">
            締切: {{ formatDate(goal.deadline) }}
          </p>
        </div>
        <Badge v-if="goal.status === 'completed'" variant="good">達成済み</Badge>
        <Badge v-else-if="goal.status === 'missed'" variant="bad">期限切れ</Badge>
      </header>

      <!-- 投票パネル -->
      <div class="shrink-0 border-b border-line bg-paper-raised px-6 py-4">
        <div class="flex items-center gap-4">
          <div class="flex-1">
            <div class="mb-1 flex items-center justify-between text-sm">
              <span class="text-ink-soft">達成投票</span>
              <span
                class="font-semibold"
                :class="(voteStore.status?.progress ?? 0) >= 90 ? 'text-good' : 'text-ink'"
              >
                {{ voteStore.status?.progress ?? 0 }}%
              </span>
            </div>
            <div class="h-2.5 overflow-hidden rounded-full bg-paper-sunken">
              <div
                class="h-full rounded-full transition-all duration-700"
                :class="progressBarClass"
                :style="{ width: `${voteStore.status?.progress ?? 0}%` }"
              />
            </div>
            <p class="mt-1 text-xs text-ink-faint">
              {{ voteStore.status?.totalMembers ?? 0 }}人中 {{ yesCount }}人が賛成
            </p>
          </div>
          <div v-if="goal.status === 'pending'" class="flex shrink-0 gap-2">
            <BaseButton
              variant="good"
              :active="voteStore.status?.myVote === true"
              @click="vote(true)"
            >
              <Icon name="check" :size="14" />YES
            </BaseButton>
            <BaseButton
              variant="bad"
              :active="voteStore.status?.myVote === false"
              @click="vote(false)"
            >
              <Icon name="x" :size="14" />NO
            </BaseButton>
          </div>
        </div>

        <!-- 投票メンバー一覧 -->
        <div class="mt-3 flex flex-wrap gap-3">
          <div
            v-for="v in voteStore.status?.votes"
            :key="v.voter.id"
            class="flex items-center gap-1.5"
          >
            <Avatar :name="v.voter.name ?? v.voter.email" :size="22" />
            <Icon
              :name="v.isYes === true ? 'check' : v.isYes === false ? 'x' : 'pending'"
              :size="13"
              :class="
                v.isYes === true ? 'text-good' : v.isYes === false ? 'text-bad' : 'text-ink-faint'
              "
            />
          </div>
        </div>
      </div>

      <!-- メッセージ -->
      <div ref="scrollArea" class="flex-1 space-y-3 overflow-y-auto p-4">
        <div v-for="msg in messageStore.messages" :key="msg.id" class="flex items-start gap-3">
          <Avatar :name="msg.author.name ?? msg.author.email" :size="36" />
          <div class="min-w-0 flex-1">
            <div class="mb-0.5 flex items-center gap-2">
              <span class="text-sm font-semibold text-ink">{{
                msg.author.name ?? msg.author.email
              }}</span>
              <span class="text-xs text-ink-faint">{{ formatDate(msg.createdAt) }}</span>
            </div>
            <p class="whitespace-pre-wrap break-words text-sm text-ink-soft">{{ msg.text }}</p>
          </div>
        </div>
      </div>

      <!-- 入力欄 -->
      <div class="shrink-0 border-t border-line bg-paper-raised p-3">
        <form class="flex gap-2" @submit.prevent="handleSend">
          <textarea
            ref="textareaRef"
            v-model="newMessage"
            placeholder="メッセージを入力..."
            rows="1"
            class="flex-1 resize-none rounded-control border border-line bg-paper-raised px-4 py-2 text-sm text-ink placeholder:text-ink-faint transition-colors focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
            @keydown.enter.exact.prevent="handleSend"
          />
          <BaseButton type="submit" :disabled="!newMessage.trim()">
            <Icon name="send" :size="14" />送信
          </BaseButton>
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
import type { Message } from '@xerovault/shared'
import { useGoalStore } from '@/stores/goal'
import { useVoteStore } from '@/stores/vote'
import { useMessageStore } from '@/stores/message'
import { useGoalEvents } from '@/composables/useGoalEvents'
import AchievementModal from '@/components/vote/AchievementModal.vue'
import Avatar from '@/components/ui/Avatar.vue'
import Icon from '@/components/ui/Icon.vue'
import Badge from '@/components/ui/Badge.vue'
import BaseButton from '@/components/ui/BaseButton.vue'

const route = useRoute()
const router = useRouter()
const goalStore = useGoalStore()
const voteStore = useVoteStore()
const messageStore = useMessageStore()

const currentGoalId = route.params.goalId as string
useGoalEvents(currentGoalId, {
  onVote: () => voteStore.fetchVoteStatus(currentGoalId),
  onMessage: (payload) => messageStore.receiveMessage(payload as Message),
})

const goal = ref(goalStore.current)
const newMessage = ref('')
const scrollArea = ref<HTMLElement | null>(null)
const showAchievement = ref(false)
const earnedPoints = ref(25)

const yesCount = computed(() => voteStore.status?.votes.filter((v) => v.isYes === true).length ?? 0)

const progressBarClass = computed(() => {
  const p = voteStore.status?.progress ?? 0
  if (p >= 90) return 'bg-good'
  if (p >= 50) return 'bg-accent'
  return 'bg-bad'
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
