<template>
  <div class="mx-auto max-w-3xl p-6">
    <div v-if="!group" class="py-16 text-center text-ink-faint">読み込み中...</div>
    <template v-else>
      <!-- ヘッダー -->
      <div class="mb-6">
        <div class="flex items-start justify-between gap-4">
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
          <div class="shrink-0 text-right">
            <p class="font-serif text-3xl font-medium text-accent">{{ group.score }}</p>
            <p class="text-xs text-ink-faint">スコア</p>
            <p
              v-if="group.streak >= 3"
              class="mt-0.5 flex items-center justify-end gap-1 text-xs font-semibold text-accent-strong"
            >
              <Icon name="flame" :size="12" />{{ group.streak }}連続達成
            </p>
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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useGroupStore } from '@/stores/group'
import { useGoalStore } from '@/stores/goal'
import { parseTags } from '@/lib/tags'
import GoalCard from '@/components/goal/GoalCard.vue'
import Avatar from '@/components/ui/Avatar.vue'
import Icon from '@/components/ui/Icon.vue'
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
const goalForm = ref({ header: '', description: '', deadline: '' })

const isOwner = computed(() => group.value?.owner.id === authStore.user?.id)
const showEditGroup = ref(false)
const savingGroup = ref(false)
const editForm = ref({ name: '', tagsInput: '' })

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
