<template>
  <div class="mx-auto max-w-2xl p-6">
    <div class="mb-6">
      <h1 class="font-serif text-2xl font-medium text-ink">ホーム</h1>
      <p class="mt-1 text-sm text-ink-soft">参加中のグループからゴールを選んで進めましょう</p>
    </div>

    <div
      v-if="!groupStore.groups.length"
      class="rounded-surface border border-line bg-paper-raised p-8 text-center"
    >
      <Icon name="target" :size="32" class="mx-auto mb-4 text-accent" />
      <h2 class="mb-2 font-serif text-lg font-medium text-ink">Xerovaultへようこそ</h2>
      <p class="mx-auto mb-6 max-w-sm text-sm text-ink-soft">
        グループで目標(ゴール)を立て、達成したかどうかをメンバー同士の投票で確認し合います。自己申告では終わらない、正直な達成管理です。
      </p>
      <div class="mx-auto mb-6 grid max-w-sm grid-cols-2 gap-3 text-left text-xs">
        <div class="rounded-control bg-paper-sunken p-3">
          <p class="font-semibold text-ink">具体的な目標</p>
          <p class="mt-1 text-ink-faint">締切と担当者を設定 → 達成+25pt / 未達成-25pt</p>
        </div>
        <div class="rounded-control bg-paper-sunken p-3">
          <p class="font-semibold text-ink">曖昧な目標</p>
          <p class="mt-1 text-ink-faint">締切・担当者なし → 達成+5pt、ペナルティなし</p>
        </div>
      </div>
      <BaseButton @click="ui.openCreateGroupDialog()">
        <Icon name="plus" :size="14" />最初のグループを作る
      </BaseButton>
    </div>

    <div v-else class="space-y-3">
      <BaseCard
        v-for="g in groupStore.groups"
        :key="g.id"
        hoverable
        class="cursor-pointer transition-opacity"
        :class="isStagnant(g.lastActivityAt) ? 'opacity-60 grayscale' : ''"
        @click="router.push(`/group/${g.id}`)"
      >
        <div class="mb-3 flex items-center justify-between">
          <div class="flex min-w-0 items-center gap-2">
            <div class="relative shrink-0">
              <Avatar :name="g.name" :size="28" />
              <span
                v-if="isStagnant(g.lastActivityAt)"
                class="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full bg-ink-faint ring-2 ring-paper-raised"
                title="7日間活動がありません"
              />
            </div>
            <h2 class="truncate font-semibold text-ink">{{ g.name }}</h2>
          </div>
          <div class="flex items-center gap-3">
            <span
              v-if="g.streak >= 3"
              class="flex items-center gap-1 text-xs font-semibold text-accent-strong"
            >
              <Icon name="flame" :size="12" />
              {{ g.streak }}連続
            </span>
            <span class="font-serif text-lg font-medium text-accent"
              >{{ g.score
              }}<span class="ml-0.5 font-sans text-xs font-normal text-ink-faint">pt</span></span
            >
          </div>
        </div>
        <p v-if="g.description" class="mb-2 truncate text-xs text-ink-soft">{{ g.description }}</p>
        <div class="flex items-center gap-4 text-xs text-ink-faint">
          <span>{{ g.members.length }}人</span>
          <span>{{ g._count?.goals ?? 0 }}ゴール</span>
          <span v-if="g.tags.length">{{ g.tags.map((t) => `#${t}`).join(' ') }}</span>
        </div>
      </BaseCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useGroupStore } from '@/stores/group'
import { useUiStore } from '@/stores/ui'
import { isStagnant } from '@/lib/activity'
import Icon from '@/components/ui/Icon.vue'
import Avatar from '@/components/ui/Avatar.vue'
import BaseCard from '@/components/ui/BaseCard.vue'
import BaseButton from '@/components/ui/BaseButton.vue'

const router = useRouter()
const groupStore = useGroupStore()
const ui = useUiStore()
</script>
