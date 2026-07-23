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
              <p v-if="group.description" class="mt-0.5 text-sm text-ink-soft">
                {{ group.description }}
              </p>
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
                <div class="flex justify-between">
                  <span>基本</span><span>{{ breakdown.base }}</span>
                </div>
                <div class="flex justify-between">
                  <span>達成による加点</span
                  ><span class="text-good">+{{ breakdown.completedPoints }}</span>
                </div>
                <div v-if="breakdown.missedCount > 0" class="flex justify-between">
                  <span>未達成（{{ breakdown.missedCount }}件）</span
                  ><span class="text-bad">-{{ breakdown.missedPenalty }}</span>
                </div>
                <div v-if="breakdown.streakBonus > 0" class="flex justify-between">
                  <span>連続達成ボーナス</span
                  ><span class="text-good">+{{ breakdown.streakBonus }}</span>
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
            @click="openManageMembers"
          >
            管理
          </button>
          <select
            v-if="isOwner && !group.isPublic"
            v-model.number="inviteExpireIn"
            class="ml-auto rounded-control border border-line bg-paper-raised px-2 py-1 text-xs text-ink-soft"
          >
            <option :value="3600">1時間で失効</option>
            <option :value="86400">24時間で失効</option>
            <option :value="259200">72時間で失効</option>
          </select>
          <BaseButton
            v-if="isOwner && !group.isPublic"
            variant="outline"
            size="sm"
            @click="handleInvite"
          >
            招待リンク作成
          </BaseButton>
          <BaseButton
            v-if="isOwner"
            variant="outline"
            size="sm"
            :class="{ 'ml-auto': group.isPublic }"
            @click="copyRequestLink"
          >
            参加リクエストリンク
          </BaseButton>
          <BaseButton
            v-if="!isMember && group.isPublic"
            size="sm"
            class="ml-auto"
            @click="router.push(`/group/${group.id}/request`)"
          >
            参加をリクエストする
          </BaseButton>
        </div>
        <div v-if="invites.length" class="mt-3 space-y-2">
          <div
            v-for="inv in invites"
            :key="inv.id"
            class="flex items-center gap-2 rounded-control bg-paper-sunken p-3 text-xs text-ink-soft"
          >
            <span class="min-w-0 flex-1 break-all">{{ inv.url }}</span>
            <span class="shrink-0 text-ink-faint">{{ formatExpiresIn(inv.expiresAt) }}</span>
            <button
              class="flex shrink-0 items-center gap-1 text-accent hover:underline"
              @click="copyInvite(inv.url)"
            >
              <Icon name="copy" :size="12" />コピー
            </button>
            <button
              class="shrink-0 text-ink-faint underline transition-colors hover:text-bad"
              @click="handleRevokeInvite(inv.id)"
            >
              失効
            </button>
          </div>
        </div>
        <div
          v-if="requestUrl"
          class="mt-3 flex items-center gap-2 rounded-control bg-paper-sunken p-3 text-xs text-ink-soft"
        >
          <span class="min-w-0 flex-1 break-all">{{ requestUrl }}</span>
          <span class="shrink-0 text-accent">コピーしました</span>
        </div>
      </div>

      <!-- セクション開閉ベルト -->
      <div class="mb-6 flex gap-2 border-b border-line pb-3">
        <button
          v-for="s in sections"
          :key="s.key"
          type="button"
          class="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-semibold transition-colors"
          :class="
            activeSection === s.key
              ? 'bg-accent text-paper'
              : 'bg-paper-sunken text-ink-soft hover:bg-paper-raised'
          "
          @click="toggleSection(s.key)"
        >
          <Icon :name="s.icon" :size="13" />{{ s.label }}
        </button>
      </div>

      <!-- スレッド一覧 -->
      <div v-if="activeSection === 'posts'" class="mb-6">
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-semibold text-ink">スレッド</h2>
          <BaseButton size="sm" @click="showNewThread = true">
            <Icon name="plus" :size="13" />新規スレッド
          </BaseButton>
        </div>
        <div v-if="!groupPostStore.threads.length" class="py-6 text-center text-xs text-ink-faint">
          まだスレッドがありません。最初のひとことを送ってみましょう
        </div>
        <div v-else class="space-y-2">
          <button
            v-for="t in groupPostStore.threads"
            :key="t.id"
            type="button"
            class="flex w-full items-center gap-3 rounded-control bg-paper-sunken p-3 text-left transition-colors hover:bg-paper-raised"
            @click="router.push(`/group/${group.id}/thread/${t.id}`)"
          >
            <Avatar :name="t.author.name ?? t.author.email" :size="36" />
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-1.5">
                <p class="truncate text-sm font-semibold text-ink">
                  {{ t.author.name ?? t.author.email }}
                </p>
                <span class="text-xs text-ink-faint">{{
                  formatRelativeTime(t.lastMessageAt)
                }}</span>
              </div>
              <p class="mt-0.5 truncate text-sm text-ink-soft">{{ t.text }}</p>
            </div>
            <span v-if="t.replyCount > 0" class="shrink-0 text-xs text-ink-faint">
              {{ t.replyCount }}件の返信
            </span>
          </button>
        </div>
      </div>

      <!-- メンバー -->
      <div v-if="activeSection === 'members'" class="mb-6">
        <h2 class="mb-3 font-semibold text-ink">メンバー</h2>
        <div class="space-y-2">
          <div
            v-for="m in sortedMembers"
            :key="m.id"
            class="flex items-start gap-3 rounded-control bg-paper-sunken p-3"
          >
            <Avatar :name="m.name ?? m.email" :size="36" />
            <div class="min-w-0 flex-1">
              <div class="flex items-center gap-1.5">
                <p class="truncate text-sm font-semibold text-ink">{{ m.name ?? m.email }}</p>
                <Badge v-if="m.id === group.owner.id" variant="info">オーナー</Badge>
              </div>
              <p class="mt-0.5 text-xs" :class="m.bio ? 'text-ink-soft' : 'italic text-ink-faint'">
                {{ m.bio || '自己紹介はまだありません' }}
              </p>
              <div class="mt-1 flex flex-wrap items-center gap-1">
                <template v-if="m.interestTags.length">
                  <Badge
                    v-for="t in m.interestTags"
                    :key="t"
                    :variant="isSharedTag(t) ? 'good' : 'info'"
                  >
                    #{{ t }}
                  </Badge>
                </template>
                <span v-else class="text-xs italic text-ink-faint">興味タグ未設定</span>
              </div>
              <p class="mt-1 text-xs text-ink-faint">
                {{ m.completedGoalsCount }}件達成 · {{ formatLastActive(m.lastActiveAt) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- 活動 -->
      <div v-if="activeSection === 'activity'" class="mb-6">
        <h2 class="mb-3 font-semibold text-ink">活動</h2>
        <div v-if="!activityStats" class="py-6 text-center text-xs text-ink-faint">
          読み込み中...
        </div>
        <template v-else>
          <div class="mb-4 rounded-control bg-paper-sunken p-3">
            <p class="text-xs text-ink-faint">
              リピート率(直近{{
                activityStats.weeklyPostCounts.length
              }}週間のうち2週以上投稿した人の割合)
            </p>
            <p class="mt-1 font-serif text-2xl font-medium text-accent">
              {{ Math.round(activityStats.repeatRate * 100) }}%
            </p>
          </div>
          <p class="mb-2 text-xs text-ink-faint">週次投稿数</p>
          <div class="space-y-1.5">
            <div
              v-for="w in activityStats.weeklyPostCounts"
              :key="w.weekStart"
              class="flex items-center gap-2"
            >
              <span class="w-16 shrink-0 text-xs text-ink-faint">{{
                formatWeek(w.weekStart)
              }}</span>
              <div class="h-3 flex-1 overflow-hidden rounded-full bg-paper-sunken">
                <div
                  class="h-full rounded-full bg-accent"
                  :style="{
                    width: `${maxWeeklyCount > 0 ? (w.count / maxWeeklyCount) * 100 : 0}%`,
                  }"
                />
              </div>
              <span class="w-6 shrink-0 text-right text-xs text-ink-soft">{{ w.count }}</span>
            </div>
          </div>
        </template>
      </div>

      <!-- ゴール一覧 -->
      <div v-if="activeSection === 'goals'">
        <div class="mb-4 flex items-center justify-between">
          <h2 class="font-semibold text-ink">ゴール一覧</h2>
          <BaseButton v-if="isMember" size="sm" @click="showAddGoal = true">
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
      </div>
    </template>

    <!-- 新規スレッド作成ダイアログ -->
    <Teleport to="body">
      <div
        v-if="showNewThread"
        class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4"
      >
        <BaseCard class="w-full max-w-md shadow-modal">
          <h2 class="mb-4 font-serif text-lg font-medium text-ink">新規スレッド</h2>
          <form class="space-y-3" @submit.prevent="handleCreateThread">
            <BaseInput
              v-model="newThreadText"
              placeholder="ひとこと挨拶してみましょう(280文字まで)"
              maxlength="280"
              required
            />
            <div class="flex gap-2 pt-2">
              <BaseButton
                type="button"
                variant="ghost"
                class="flex-1 justify-center"
                @click="showNewThread = false"
              >
                キャンセル
              </BaseButton>
              <BaseButton
                type="submit"
                :disabled="creatingThread || !newThreadText.trim()"
                class="flex-1 justify-center"
              >
                {{ creatingThread ? '作成中...' : '作成' }}
              </BaseButton>
            </div>
          </form>
        </BaseCard>
      </div>
    </Teleport>

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
      <div
        v-if="showEditGroup"
        class="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4"
      >
        <BaseCard class="w-full max-w-md shadow-modal">
          <h2 class="mb-4 font-serif text-lg font-medium text-ink">グループを編集</h2>
          <form class="space-y-3" @submit.prevent="handleEditGroup">
            <BaseInput v-model="editForm.name" placeholder="グループ名 *" required />
            <BaseTextarea
              v-model="editForm.description"
              placeholder="グループの説明（任意・200文字まで）"
              rows="2"
              maxlength="200"
            />
            <TagAutocompleteInput
              v-model="editForm.tagsInput"
              placeholder="タグ（カンマ区切りで複数入力可・任意）"
            />
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

          <template v-if="joinRequests.length">
            <h3 class="mb-2 text-xs font-medium text-ink-faint">参加リクエスト</h3>
            <div class="mb-4 max-h-60 space-y-2 overflow-y-auto">
              <div
                v-for="r in joinRequests"
                :key="r.id"
                class="rounded-control bg-paper-sunken p-2"
              >
                <div class="flex items-center gap-2">
                  <Avatar :name="r.user.name ?? r.user.email" :size="28" />
                  <span class="min-w-0 flex-1 truncate text-sm text-ink">{{
                    r.user.name ?? r.user.email
                  }}</span>
                  <button
                    class="shrink-0 text-xs font-medium text-accent hover:underline"
                    @click="handleApproveRequest(r.id)"
                  >
                    承認
                  </button>
                  <button
                    class="shrink-0 text-xs text-ink-faint underline transition-colors hover:text-bad"
                    @click="handleRejectRequest(r.id)"
                  >
                    却下
                  </button>
                </div>
                <p v-if="r.message" class="mt-1 truncate pl-9 text-xs text-ink-soft">
                  {{ r.message }}
                </p>
              </div>
            </div>
          </template>

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

          <template v-if="bannedMembers.length">
            <h3 class="mb-2 mt-4 text-xs font-medium text-ink-faint">除名済み(再参加不可)</h3>
            <div class="max-h-40 space-y-1 overflow-y-auto">
              <div
                v-for="m in bannedMembers"
                :key="m.id"
                class="flex items-center gap-2 rounded-control px-2 py-1.5 hover:bg-paper-sunken"
              >
                <Avatar :name="m.name ?? '(不明)'" :size="24" />
                <span class="min-w-0 flex-1 truncate text-sm text-ink-soft">{{
                  m.name ?? '(不明)'
                }}</span>
                <button
                  class="shrink-0 text-xs text-ink-faint underline transition-colors hover:text-ink"
                  @click="handleUnban(m.id)"
                >
                  解除
                </button>
              </div>
            </div>
          </template>

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
import type {
  ScoreBreakdown,
  BannedMember,
  GroupJoinRequest,
  GroupActivityStats,
} from '@sodalis/shared'
import { useAuthStore } from '@/stores/auth'
import { useGroupStore } from '@/stores/group'
import { useGoalStore } from '@/stores/goal'
import { useGroupPostStore } from '@/stores/groupPost'
import { parseTags } from '@/lib/tags'
import { isStagnant, formatLastActive, formatRelativeTime } from '@/lib/activity'
import { copyToClipboard } from '@/utils/clipboard'
import { supabase } from '@/lib/supabase'
import GoalCard from '@/components/goal/GoalCard.vue'
import Avatar from '@/components/ui/Avatar.vue'
import Icon, { type IconName } from '@/components/ui/Icon.vue'
import Badge from '@/components/ui/Badge.vue'
import BaseButton from '@/components/ui/BaseButton.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseInput from '@/components/ui/BaseInput.vue'
import BaseTextarea from '@/components/ui/BaseTextarea.vue'
import TagAutocompleteInput from '@/components/ui/TagAutocompleteInput.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const groupStore = useGroupStore()
const goalStore = useGoalStore()
const groupPostStore = useGroupPostStore()
const group = ref(groupStore.current)
const invites = ref<{ id: string; url: string; expiresAt: string }[]>([])
const inviteExpireIn = ref(259200)
const requestUrl = ref('')
const showAddGoal = ref(false)
const addingGoal = ref(false)
const goalForm = ref({ header: '', description: '', deadline: '', assigneeId: '' })
const showNewThread = ref(false)
const newThreadText = ref('')
const creatingThread = ref(false)

type SectionKey = 'posts' | 'members' | 'goals' | 'activity'
const sections: { key: SectionKey; label: string; icon: IconName }[] = [
  { key: 'goals', label: 'ゴール一覧', icon: 'target' },
  { key: 'members', label: 'メンバー', icon: 'users' },
  { key: 'posts', label: 'スレッド', icon: 'send' },
  { key: 'activity', label: '活動', icon: 'ranking' },
]
const initialSection = sections.find((s) => s.key === route.query.section)?.key ?? 'goals'
const activeSection = ref<SectionKey>(initialSection)
const activityStats = ref<GroupActivityStats | null>(null)
const maxWeeklyCount = computed(() =>
  Math.max(0, ...(activityStats.value?.weeklyPostCounts.map((w) => w.count) ?? [0]))
)
function formatWeek(weekStart: string): string {
  const d = new Date(weekStart)
  return `${d.getMonth() + 1}/${d.getDate()}`
}
async function toggleSection(key: SectionKey): Promise<void> {
  activeSection.value = key
  if (key === 'activity' && !activityStats.value) {
    activityStats.value = await groupStore.fetchActivityStats(route.params.id as string)
  }
}

const isOwner = computed(() => group.value?.owner.id === authStore.user?.id)
const sortedMembers = computed(() => {
  if (!group.value) return []
  const ownerId = group.value.owner.id
  return [...group.value.members].sort((a, b) => {
    if (a.id === ownerId) return -1
    if (b.id === ownerId) return 1
    return 0
  })
})
const isMember = computed(
  () => group.value?.members.some((m) => m.id === authStore.user?.id) ?? false
)
const myInterestTags = ref<string[]>([])
function isSharedTag(tag: string): boolean {
  return myInterestTags.value.includes(tag)
}
const showEditGroup = ref(false)
const savingGroup = ref(false)
const editForm = ref({ name: '', description: '', tagsInput: '' })

const showBreakdown = ref(false)
const breakdown = ref<ScoreBreakdown | null>(null)

const showManageMembers = ref(false)
const bannedMembers = ref<BannedMember[]>([])
const joinRequests = ref<GroupJoinRequest[]>([])

async function openManageMembers() {
  showManageMembers.value = true
  bannedMembers.value = await groupStore.fetchBannedMembers(route.params.id as string)
  joinRequests.value = await groupStore.fetchJoinRequests(route.params.id as string)
}

async function handleUnban(userId: string) {
  await groupStore.unbanMember(route.params.id as string, userId)
  bannedMembers.value = bannedMembers.value.filter((m) => m.id !== userId)
}

async function handleApproveRequest(requestId: string) {
  await groupStore.approveJoinRequest(requestId)
  joinRequests.value = joinRequests.value.filter((r) => r.id !== requestId)
  group.value = await groupStore.fetchGroup(route.params.id as string)
}

async function handleRejectRequest(requestId: string) {
  await groupStore.rejectJoinRequest(requestId)
  joinRequests.value = joinRequests.value.filter((r) => r.id !== requestId)
}

onMounted(async () => {
  const id = route.params.id as string
  group.value = await groupStore.fetchGroup(id)
  await goalStore.fetchGoals(id)
  await groupPostStore.fetchThreads(id)

  if (authStore.user) {
    const { data } = await supabase
      .from('profiles')
      .select('interest_tags')
      .eq('id', authStore.user.id)
      .single()
    myInterestTags.value = data?.interest_tags ?? []
  }

  if (activeSection.value === 'activity') {
    activityStats.value = await groupStore.fetchActivityStats(id)
  }

  if (isOwner.value && !group.value.isPublic) {
    invites.value = await groupStore.fetchInvites(id)
  }
})

async function handleCreateThread() {
  if (!newThreadText.value.trim()) return
  creatingThread.value = true
  try {
    const thread = await groupPostStore.createThread(route.params.id as string, newThreadText.value)
    newThreadText.value = ''
    showNewThread.value = false
    router.push(`/group/${route.params.id}/thread/${thread.id}`)
  } finally {
    creatingThread.value = false
  }
}

async function handleInvite() {
  const id = route.params.id as string
  const invite = await groupStore.createInvite(id, inviteExpireIn.value)
  invites.value.unshift(invite)
}

function formatExpiresIn(iso: string): string {
  const ms = new Date(iso).getTime() - Date.now()
  if (ms <= 0) return '期限切れ'
  const hours = Math.ceil(ms / (60 * 60 * 1000))
  if (hours < 24) return `残り${hours}時間`
  return `残り${Math.ceil(hours / 24)}日`
}

function copyInvite(url: string) {
  copyToClipboard(url)
}

async function handleRevokeInvite(inviteId: string) {
  await groupStore.revokeInvite(inviteId)
  invites.value = invites.value.filter((inv) => inv.id !== inviteId)
}

function copyRequestLink() {
  const id = route.params.id as string
  requestUrl.value = `${window.location.origin}/group/${id}/request`
  copyToClipboard(requestUrl.value)
}

async function toggleBreakdown() {
  showBreakdown.value = !showBreakdown.value
  if (showBreakdown.value && !breakdown.value) {
    breakdown.value = await groupStore.fetchScoreBreakdown(route.params.id as string)
  }
}

async function handleRemoveMember(memberId: string) {
  if (!confirm('このメンバーをグループから除名しますか?再参加もできなくなります。')) return
  await groupStore.removeMember(route.params.id as string, memberId)
  group.value = groupStore.current
  bannedMembers.value = await groupStore.fetchBannedMembers(route.params.id as string)
}

function openEditDialog() {
  if (!group.value) return
  editForm.value = {
    name: group.value.name,
    description: group.value.description ?? '',
    tagsInput: group.value.tags.join(', '),
  }
  showEditGroup.value = true
}

async function handleEditGroup() {
  savingGroup.value = true
  try {
    group.value = await groupStore.updateGroup(route.params.id as string, {
      name: editForm.value.name,
      description: editForm.value.description,
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
