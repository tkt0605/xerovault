<template>
  <div class="mx-auto max-w-3xl p-6">
    <div v-if="!group" class="py-16 text-center text-ink-faint">読み込み中...</div>
    <template v-else>
      <!-- ヘッダー -->
      <div class="mb-6">
        <div class="flex items-start justify-between gap-4">
          <div class="flex min-w-0 items-start gap-3">
            <div class="relative mt-0.5 shrink-0">
              <Avatar :name="group.name" :size="80" />
              <span
                v-if="isStagnant(group.lastActivityAt)"
                class="absolute bottom-0.5 right-0.5 h-4 w-4 rounded-full bg-ink-faint ring-2 ring-paper"
                title="7日間活動がありません"
              />
            </div>
            <div class="min-w-0">
              <div class="flex items-center gap-1.5">
                <h1 class="truncate font-serif text-2xl font-medium text-ink">{{ group.name }}</h1>
                <button
                  v-if="isOwner"
                  class="shrink-0 text-ink-faint transition-colors hover:text-ink"
                  title="グループを編集"
                  @click="openEditDialog"
                >
                  <Icon name="edit" :size="15" />
                </button>
              </div>
              <p v-if="group.tags.length" class="mt-0.5 text-sm text-ink-soft">
                {{ group.tags.map((t) => `#${t}`).join(' ') }}
              </p>
            </div>
          </div>
          <div class="relative shrink-0 text-right">
            <button class="text-right" @click="toggleBreakdown">
              <p class="font-serif text-3xl font-medium text-accent">{{ group.score }}</p>
              <p class="text-xs text-ink-faint underline decoration-dotted">スコア</p>
              <p
                v-if="group.streak >= 3"
                class="mt-0.5 flex items-center justify-end gap-1 text-xs font-semibold text-accent-strong"
              >
                <Icon name="flame" :size="12" />{{ group.streak }}連続達成
              </p>
            </button>
            <div
              v-if="showBreakdown"
              class="absolute right-0 top-full z-10 mt-2 w-56 rounded-surface border border-line bg-paper-raised p-3 text-left shadow-card"
            >
              <div v-if="breakdown" class="space-y-1 text-xs text-ink-soft">
                <div class="flex justify-between"><span>基本</span><span>{{ breakdown.base }}</span></div>
                <div class="flex justify-between">
                  <span>達成による加点</span><span class="text-good">+{{ breakdown.completedPoints }}</span>
                </div>
                <div v-if="breakdown.missedCount > 0" class="flex justify-between">
                  <span>未達成（{{ breakdown.missedCount }}件）</span
                  ><span class="text-bad">-{{ breakdown.missedPenalty }}</span>
                </div>
                <div v-if="breakdown.streakBonus > 0" class="flex justify-between">
                  <span>連続達成ボーナス</span><span class="text-good">+{{ breakdown.streakBonus }}</span>
                </div>
                <div
                  class="mt-1.5 flex justify-between border-t border-line pt-1.5 font-semibold text-ink"
                >
                  <span>合計</span><span>{{ breakdown.total }}</span>
                </div>
              </div>
              <p v-else class="text-xs text-ink-faint">計算中...</p>
            </div>
          </div>
        </div>
        <div class="mt-4 flex flex-wrap items-center gap-3">
          <div class="flex -space-x-2">
            <Avatar
              v-for="m in group.members.slice(0, 5)"
              :key="m.id"
              :name="m.name ?? m.email"
              :size="32"
              class="ring-2 ring-paper-raised"
            />
          </div>
          <span class="text-sm text-ink-soft">{{ group.members.length }}人のメンバー</span>
          <button
            v-if="isOwner"
            class="text-xs text-ink-faint transition-colors hover:text-ink"
            @click="showManageMembers = true"
          >
            管理
          </button>
          <BaseButton variant="outline" size="sm" class="ml-auto" @click="handleInvite">
            招待リンク作成
          </BaseButton>
        </div>
        <div
          v-if="inviteUrl"
          class="mt-3 flex items-center gap-2 rounded-control bg-paper-sunken p-3 text-xs text-ink-soft"
        >
          <span class="min-w-0 flex-1 break-all">{{ inviteUrl }}</span>
          <button
            class="flex shrink-0 items-center gap-1 text-accent hover:underline"
            @click="copyInvite"
          >
            <Icon name="copy" :size="12" />コピー
          </button>
        </div>
      </div>

      <!-- ゴール一覧 -->
      <div class="mb-4 flex items-center justify-between">
        <h2 class="font-semibold text-ink">ゴール一覧</h2>
        <BaseButton size="sm" @click="showAddGoal = true">
          <Icon name="plus" :size="13" />ゴール追加
        </BaseButton>
      </div>

      <div v-if="!goalStore.goals.length" class="py-12 text-center text-ink-faint">
        <Icon name="target" :size="28" class="mx-auto mb-3" />
        <p class="font-medium text-ink-soft">ゴールがまだありません</p>
      </div>
      <div v-else class="space-y-3">
        <GoalCard
          v-for="g in goalStore.goals"
          :key="g.id"
          :goal="g"
          @click="router.push(`/group/${group.id}/goal/${g.id}`)"
        />
      </div>
    </template>

    <!-- ゴール追加ダイアログ -->
    <Teleport to="body">
      <div v-if="showAddGoal" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40">
        <BaseCard class="w-full max-w-md shadow-modal">
          <h2 class="mb-4 font-serif text-lg font-medium text-ink">ゴールを追加</h2>
          <form class="space-y-3" @submit.prevent="handleAddGoal">
            <BaseInput v-model="goalForm.header" placeholder="タイトル（任意）" />
            <BaseTextarea
              v-model="goalForm.description"
              placeholder="ゴールの内容 *"
              required
              rows="3"
            />
            <BaseInput v-model="goalForm.deadline" type="datetime-local" />
            <select
              v-model="goalForm.assigneeId"
              class="w-full rounded-control border border-line bg-paper-raised px-3 py-2 text-sm text-ink focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
            >
              <option value="">担当者なし</option>
              <option v-for="m in group?.members" :key="m.id" :value="m.id">
                {{ m.name ?? m.email }}
              </option>
            </select>
            <p class="text-xs text-ink-faint">
              締切と担当者を両方設定すると「具体的な目標」として高スコア(達成25pt/未達成-25pt)になります
            </p>
            <div class="flex gap-2 pt-2">
              <BaseButton
                type="button"
                variant="ghost"
                class="flex-1 justify-center"
                @click="showAddGoal = false"
              >
                キャンセル
              </BaseButton>
              <BaseButton type="submit" :disabled="addingGoal" class="flex-1 justify-center">
                {{ addingGoal ? '追加中...' : '追加' }}
              </BaseButton>
            </div>
          </form>
        </BaseCard>
      </div>
    </Teleport>

    <!-- グループ編集ダイアログ（オーナーのみ） -->
    <Teleport to="body">
      <div v-if="showEditGroup" class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4">
        <BaseCard class="w-full max-w-md shadow-modal">
          <h2 class="mb-4 font-serif text-lg font-medium text-ink">グループを編集</h2>
          <form class="space-y-3" @submit.prevent="handleEditGroup">
            <BaseInput v-model="editForm.name" placeholder="グループ名 *" required />
            <BaseInput v-model="editForm.tagsInput" placeholder="タグ（カンマ区切りで複数入力可・任意）" />
            <div class="flex gap-2 pt-2">
              <BaseButton
                type="button"
                variant="ghost"
                class="flex-1 justify-center"
                @click="showEditGroup = false"
              >
                キャンセル
              </BaseButton>
              <BaseButton type="submit" :disabled="savingGroup" class="flex-1 justify-center">
                {{ savingGroup ? '保存中...' : '保存' }}
              </BaseButton>
            </div>
          </form>
        </BaseCard>
      </div>
    </Teleport>

    <!-- メンバー管理ダイアログ（オーナーのみ） -->
    <Teleport to="body">
      <div
        v-if="showManageMembers"
        class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4"
      >
        <BaseCard class="w-full max-w-md shadow-modal">
          <h2 class="mb-4 font-serif text-lg font-medium text-ink">メンバー管理</h2>
          <div class="max-h-80 space-y-1 overflow-y-auto">
            <div
              v-for="m in group?.members"
              :key="m.id"
              class="flex items-center gap-2 rounded-control px-2 py-1.5 hover:bg-paper-sunken"
            >
              <Avatar :name="m.name ?? m.email" :size="28" />
              <span class="min-w-0 flex-1 truncate text-sm text-ink">{{ m.name ?? m.email }}</span>
              <Badge v-if="m.id === group?.owner.id" variant="info">オーナー</Badge>
              <button
                v-else
                class="shrink-0 text-ink-faint transition-colors hover:text-bad"
                title="除名"
                @click="handleRemoveMember(m.id)"
              >
                <Icon name="trash" :size="14" />
              </button>
            </div>
          </div>
          <div class="flex justify-end pt-4">
            <BaseButton variant="ghost" @click="showManageMembers = false">閉じる</BaseButton>
          </div>
        </BaseCard>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { ScoreBreakdown } from '@xerovault/shared'
import { useAuthStore } from '@/stores/auth'
import { useGroupStore } from '@/stores/group'
import { useGoalStore } from '@/stores/goal'
import { parseTags } from '@/lib/tags'
import { isStagnant } from '@/lib/activity'
import GoalCard from '@/components/goal/GoalCard.vue'
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
const groupStore = useGroupStore()
const goalStore = useGoalStore()
const group = ref(groupStore.current)
const inviteUrl = ref('')
const showAddGoal = ref(false)
const addingGoal = ref(false)
const goalForm = ref({ header: '', description: '', deadline: '', assigneeId: '' })

const isOwner = computed(() => group.value?.owner.id === authStore.user?.id)
const showEditGroup = ref(false)
const savingGroup = ref(false)
const editForm = ref({ name: '', tagsInput: '' })

const showBreakdown = ref(false)
const breakdown = ref<ScoreBreakdown | null>(null)

const showManageMembers = ref(false)

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

async function toggleBreakdown() {
  showBreakdown.value = !showBreakdown.value
  if (showBreakdown.value && !breakdown.value) {
    breakdown.value = await groupStore.fetchScoreBreakdown(route.params.id as string)
  }
}

async function handleRemoveMember(memberId: string) {
  if (!confirm('このメンバーをグループから除名しますか?')) return
  await groupStore.removeMember(route.params.id as string, memberId)
  group.value = groupStore.current
}

function openEditDialog() {
  if (!group.value) return
  editForm.value = { name: group.value.name, tagsInput: group.value.tags.join(', ') }
  showEditGroup.value = true
}

async function handleEditGroup() {
  savingGroup.value = true
  try {
    group.value = await groupStore.updateGroup(route.params.id as string, {
      name: editForm.value.name,
      tags: parseTags(editForm.value.tagsInput),
    })
    showEditGroup.value = false
  } finally {
    savingGroup.value = false
  }
}

async function handleAddGoal() {
  addingGoal.value = true
  try {
    await goalStore.createGoal(route.params.id as string, {
      header: goalForm.value.header,
      description: goalForm.value.description,
      deadline: goalForm.value.deadline || null,
      assigneeId: goalForm.value.assigneeId || null,
    })
    showAddGoal.value = false
    goalForm.value = { header: '', description: '', deadline: '', assigneeId: '' }
  } finally {
    addingGoal.value = false
  }
}
</script>
