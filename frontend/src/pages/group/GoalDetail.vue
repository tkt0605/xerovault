<template>
  <div class="flex h-[calc(100vh-57px)] flex-col">
    <div v-if="!goal" class="flex flex-1 items-center justify-center text-ink-faint">
      読み込み中...
    </div>
    <template v-else>
      <!-- ヘッダー -->
      <div class="shrink-0 mx-auto w-full max-w-3xl p-6 pb-0">
        <button
          class="mb-2 flex items-center gap-1 text-xs text-ink-faint transition-colors hover:text-paper"
          @click="router.push(`/group/${goal.group?.id}`)"
        >
          <Icon name="chevron-left" :size="13" />
          {{ goal.group?.name ?? 'グループへ' }}
        </button>
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <div class="flex items-center gap-1.5">
              <h1 class="truncate font-serif text-lg font-medium text-ink">
                {{ goal.header || goal.description }}
              </h1>
              <button
                class="shrink-0 text-ink-faint transition-colors hover:text-ink"
                title="ゴールを編集"
                @click="openEditDialog"
              >
                <Icon name="edit" :size="13" />
              </button>
              <button
                class="shrink-0 text-ink-faint transition-colors hover:text-bad"
                title="ゴールを削除"
                @click="handleDeleteGoal"
              >
                <Icon name="trash" :size="13" />
              </button>
            </div>
            <p v-if="goal.assignee" class="mt-0.5 text-xs text-ink-faint">
              担当: {{ goal.assignee.name ?? goal.assignee.email }}
            </p>
            <p v-if="goal.deadline" class="mt-0.5 text-xs text-ink-faint">
              締切: {{ formatDate(goal.deadline) }}
            </p>
          </div>
          <Badge v-if="goal.status === 'completed'" variant="good" class="shrink-0">達成済み</Badge>
          <Badge v-else-if="goal.status === 'missed'" variant="bad" class="shrink-0"
            >期限切れ</Badge
          >
        </div>
      </div>
      <!-- 投票パネル -->
      <div class="shrink-0 mx-auto w-full max-w-3xl p-6">
        <BaseCard :padded="false" class="p-4">
          <div class="flex items-baseline justify-between">
            <span class="text-sm text-ink-soft">達成投票</span>
            <span
              class="font-serif text-2xl font-medium"
              :class="(voteStore.status?.progress ?? 0) >= 90 ? 'text-good' : 'text-ink'"
            >
              {{ voteStore.status?.progress ?? 0
              }}<span class="text-sm font-sans text-ink-faint">%</span>
            </span>
          </div>
          <div class="mt-1.5 h-2 overflow-hidden rounded-full bg-paper-sunken">
            <div
              class="h-full rounded-full transition-all duration-700"
              :class="progressBarClass"
              :style="{ width: `${voteStore.status?.progress ?? 0}%` }"
            />
          </div>
          <p class="mt-1.5 text-xs text-ink-faint">
            {{ voteStore.status?.totalMembers ?? 0 }}人中 {{ yesCount }}人が賛成
          </p>

          <div v-if="goal.status === 'pending'" class="mt-3 flex gap-2">
            <BaseButton
              variant="good"
              :active="voteStore.status?.myVote === true"
              class="flex-1 justify-center"
              @click="vote(true)"
            >
              <Icon name="check" :size="14" />YES
            </BaseButton>
            <BaseButton
              variant="bad"
              :active="voteStore.status?.myVote === false"
              class="flex-1 justify-center"
              @click="vote(false)"
            >
              <Icon name="x" :size="14" />NO
            </BaseButton>
          </div>

          <!-- 投票メンバー -->
          <div v-if="voteStore.status?.votes.length" class="mt-3 flex flex-wrap gap-x-1 gap-y-2">
            <div v-for="v in voteStore.status?.votes" :key="v.voter.id" class="relative">
              <Avatar
                :name="v.voter.name ?? v.voter.email"
                :size="28"
                class="ring-2 ring-paper-raised"
              />
              <span
                class="absolute -bottom-0.5 -right-0.5 flex h-3.5 w-3.5 items-center justify-center rounded-full ring-2 ring-paper-raised"
                :class="
                  v.isYes === true ? 'bg-good' : v.isYes === false ? 'bg-bad' : 'bg-paper-sunken'
                "
              >
                <Icon
                  :name="v.isYes === true ? 'check' : v.isYes === false ? 'x' : 'pending'"
                  :size="8"
                  :class="v.isYes === null ? 'text-ink-faint' : 'text-paper-raised'"
                />
              </span>
            </div>
          </div>
        </BaseCard>
      </div>

      <!-- メッセージ -->
      <div ref="scrollArea" class="flex-1 overflow-y-auto p-4">
        <div class="mx-auto w-full max-w-3xl space-y-3">
          <div
            v-for="msg in messageStore.messages"
            :key="msg.id"
            class="flex items-start gap-2"
            :class="isMine(msg) ? 'flex-row-reverse' : ''"
          >
            <Avatar v-if="!isMine(msg)" :name="msg.author.name ?? msg.author.email" :size="32" />
            <div class="min-w-0 max-w-[75%]" :class="isMine(msg) ? 'flex flex-col items-end' : ''">
              <div
                class="mb-0.5 flex items-center gap-2 text-xs"
                :class="isMine(msg) ? 'flex-row-reverse' : ''"
              >
                <span v-if="!isMine(msg)" class="font-semibold text-ink">{{
                  msg.author.name ?? msg.author.email
                }}</span>
                <span class="text-ink-faint">{{ formatDate(msg.createdAt) }}</span>
              </div>
              <div
                class="whitespace-pre-wrap break-words rounded-surface px-3.5 py-2 text-sm"
                :class="isMine(msg) ? 'bg-accent text-paper-raised' : 'bg-paper-sunken text-ink'"
              >
                {{ msg.text }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 入力欄 -->
      <div class="shrink-0 border-t border-line bg-paper-raised p-3">
        <form class="mx-auto flex w-full max-w-3xl gap-2" @submit.prevent="handleSend">
          <textarea
            ref="textareaRef"
            v-model="newMessage"
            placeholder="メッセージを入力..."
            rows="1"
            class="flex-1 resize-none rounded-control border border-line bg-paper-raised px-4 py-2 text-sm text-ink placeholder:text-ink-faint transition-colors focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
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

    <!-- ゴール編集ダイアログ -->
    <Teleport to="body">
      <div v-if="showEditGoal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4">
        <BaseCard class="w-full max-w-md shadow-modal">
          <h2 class="mb-4 font-serif text-lg font-medium text-ink">ゴールを編集</h2>
          <form class="space-y-3" @submit.prevent="handleEditGoal">
            <BaseInput v-model="editForm.header" placeholder="タイトル（任意）" />
            <BaseTextarea v-model="editForm.description" placeholder="ゴールの内容 *" required rows="3" />
            <BaseInput v-model="editForm.deadline" type="datetime-local" />
            <select
              v-model="editForm.assigneeId"
              class="w-full rounded-control border border-line bg-paper-raised px-3 py-2 text-sm text-ink focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
            >
              <option value="">担当者なし</option>
              <option v-for="m in goal?.group?.members" :key="m.id" :value="m.id">
                {{ m.name ?? m.email }}
              </option>
            </select>
            <div class="flex gap-2 pt-2">
              <BaseButton
                type="button"
                variant="ghost"
                class="flex-1 justify-center"
                @click="showEditGoal = false"
              >
                キャンセル
              </BaseButton>
              <BaseButton type="submit" :disabled="savingGoal" class="flex-1 justify-center">
                {{ savingGoal ? '保存中...' : '保存' }}
              </BaseButton>
            </div>
          </form>
        </BaseCard>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { Message } from '@xerovault/shared'
import { useAuthStore } from '@/stores/auth'
import { useGoalStore } from '@/stores/goal'
import { useVoteStore } from '@/stores/vote'
import { useMessageStore } from '@/stores/message'
import { useGoalEvents } from '@/composables/useGoalEvents'
import AchievementModal from '@/components/vote/AchievementModal.vue'
import Avatar from '@/components/ui/Avatar.vue'
import Icon from '@/components/ui/Icon.vue'
import Badge from '@/components/ui/Badge.vue'
import BaseButton from '@/components/ui/BaseButton.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseInput from '@/components/ui/BaseInput.vue'
import BaseTextarea from '@/components/ui/BaseTextarea.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const goalStore = useGoalStore()
const voteStore = useVoteStore()
const messageStore = useMessageStore()

const currentGoalId = route.params.goalId as string
useGoalEvents(currentGoalId, {
  onVote: () => voteStore.fetchVoteStatus(currentGoalId),
  onMessage: () => messageStore.fetchMessages(currentGoalId),
})

const goal = ref(goalStore.current)
const newMessage = ref('')
const scrollArea = ref<HTMLElement | null>(null)
const showAchievement = ref(false)
const earnedPoints = ref(25)

const showEditGoal = ref(false)
const savingGoal = ref(false)
const editForm = ref({ header: '', description: '', deadline: '', assigneeId: '' })

const yesCount = computed(() => voteStore.status?.votes.filter((v) => v.isYes === true).length ?? 0)

const progressBarClass = computed(() => {
  const p = voteStore.status?.progress ?? 0
  if (p >= 90) return 'bg-good'
  if (p >= 50) return 'bg-accent'
  return 'bg-bad'
})

function isMine(msg: Message): boolean {
  return msg.authorId === authStore.user?.id
}

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

function toDatetimeLocal(d: string) {
  const date = new Date(d)
  const offset = date.getTimezoneOffset()
  return new Date(date.getTime() - offset * 60000).toISOString().slice(0, 16)
}

function openEditDialog() {
  if (!goal.value) return
  editForm.value = {
    header: goal.value.header ?? '',
    description: goal.value.description,
    deadline: goal.value.deadline ? toDatetimeLocal(goal.value.deadline) : '',
    assigneeId: goal.value.assigneeId ?? '',
  }
  showEditGoal.value = true
}

async function handleEditGoal() {
  savingGoal.value = true
  try {
    goal.value = await goalStore.updateGoal(route.params.goalId as string, {
      header: editForm.value.header,
      description: editForm.value.description,
      deadline: editForm.value.deadline || null,
      assigneeId: editForm.value.assigneeId || null,
    })
    showEditGoal.value = false
  } finally {
    savingGoal.value = false
  }
}

async function handleDeleteGoal() {
  if (!confirm('このゴールを削除しますか?')) return
  await goalStore.deleteGoal(route.params.goalId as string)
  router.push(`/group/${route.params.id}`)
}
</script>
