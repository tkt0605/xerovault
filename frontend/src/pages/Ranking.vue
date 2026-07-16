<template>
  <div class="mx-auto max-w-2xl p-6">
    <h1 class="mb-2 font-serif text-2xl font-medium text-ink">スコアランキング</h1>
    <p class="mb-6 text-sm text-ink-soft">公開中の全グループの合意スコアランキングです</p>

    <div class="space-y-2">
      <BaseCard
        v-for="(g, i) in groups"
        :key="g.id"
        :padded="false"
        class="flex items-center gap-4 p-4"
      >
        <div
          class="w-8 text-center font-serif text-lg font-medium"
          :class="
            i === 0
              ? 'text-accent'
              : i === 1
                ? 'text-ink-soft'
                : i === 2
                  ? 'text-ink-faint'
                  : 'text-ink-faint'
          "
        >
          {{ i + 1 }}
        </div>
        <div class="min-w-0 flex-1">
          <div class="flex items-center gap-2">
            <p class="truncate font-semibold text-ink">{{ g.name }}</p>
            <span v-if="g.streak >= 3" class="flex items-center gap-0.5 text-xs text-accent-strong">
              <Icon name="flame" :size="11" />{{ g.streak }}
            </span>
          </div>
          <p class="text-xs text-ink-faint">
            {{ g._count.members }}人 · {{ g._count.goals }}ゴール<span v-if="g.tags.length">
              · {{ g.tags.map((t) => `#${t}`).join(' ') }}</span
            >
          </p>
        </div>
        <p class="shrink-0 font-serif text-xl font-medium text-accent">
          {{ g.score }}<span class="ml-0.5 font-sans text-xs font-normal text-ink-faint">pt</span>
        </p>
      </BaseCard>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import type { RankingGroup } from '@xerovault/shared'
import { rpc } from '@/lib/rpc'
import Icon from '@/components/ui/Icon.vue'
import BaseCard from '@/components/ui/BaseCard.vue'

const groups = ref<RankingGroup[]>([])
onMounted(async () => {
  groups.value = await rpc<RankingGroup[]>('get_rankings', { p_limit: 20 })
})
</script>
