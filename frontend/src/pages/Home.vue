<template>
  <div class="mx-auto max-w-2xl p-6">
    <div class="mb-6">
      <h1 class="font-serif text-2xl font-medium text-ink">ホーム</h1>
      <p class="mt-1 text-sm text-ink-soft">参加中のグループからゴールを選んで進めましょう</p>
    </div>

    <div v-if="!groupStore.groups.length" class="py-16 text-center text-ink-faint">
      <Icon name="users" :size="32" class="mx-auto mb-4" />
      <p class="font-medium text-ink-soft">グループがまだありません</p>
      <p class="mt-1 text-sm">左のサイドバーから作成してください</p>
    </div>

    <div v-else class="space-y-3">
      <BaseCard
        v-for="g in groupStore.groups"
        :key="g.id"
        hoverable
        class="cursor-pointer"
        @click="router.push(`/group/${g.id}`)"
      >
        <div class="mb-3 flex items-center justify-between">
          <h2 class="font-semibold text-ink">{{ g.name }}</h2>
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
        <div class="flex items-center gap-4 text-xs text-ink-faint">
          <span>{{ g.members.length }}人</span>
          <span>{{ g._count?.goals ?? 0 }}ゴール</span>
          <span v-if="g.tag">#{{ g.tag }}</span>
        </div>
      </BaseCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useGroupStore } from '@/stores/group'
import Icon from '@/components/ui/Icon.vue'
import BaseCard from '@/components/ui/BaseCard.vue'

const router = useRouter()
const groupStore = useGroupStore()
</script>
