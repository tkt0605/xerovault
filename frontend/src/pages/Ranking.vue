<template>
  <div class="mx-auto max-w-2xl p-6">
    <h1 class="mb-2 font-serif text-2xl font-medium text-ink">スコアランキング</h1>
    <p class="text-sm text-ink-soft">
      <template v-if="activeTag">「#{{ activeTag }}」の公開グループです</template>
      <template v-else>公開中の全グループの合意スコアランキングです</template>
    </p>
    <button
      v-if="activeTag"
      type="button"
      class="mb-4 text-xs font-semibold text-accent-strong hover:underline"
      @click="clearTag"
    >
      すべて表示
    </button>
    <div v-else class="mb-4" />

    <p v-if="!groups.length" class="rounded-surface border border-line bg-paper-raised p-6 text-center text-sm text-ink-faint">
      該当する公開グループはありません
    </p>
    <div v-else class="space-y-2">
      <BaseCard
        v-for="(g, i) in groups"
        :key="g.id"
        :padded="false"
        class="flex cursor-pointer items-center gap-4 p-4"
        @click="router.push(`/group/${g.id}`)"
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
        <Avatar :name="g.name" :size="28" />
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
import { ref, computed, watch, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { RankingGroup } from '@xerovault/shared'
import { rpc } from '@/lib/rpc'
import Icon from '@/components/ui/Icon.vue'
import Avatar from '@/components/ui/Avatar.vue'
import BaseCard from '@/components/ui/BaseCard.vue'

const route = useRoute()
const router = useRouter()

const groups = ref<RankingGroup[]>([])
const activeTag = computed(() => {
  const tag = route.query.tag
  return typeof tag === 'string' && tag ? tag : null
})

async function fetchRankings(): Promise<void> {
  groups.value = await rpc<RankingGroup[]>('get_rankings', {
    p_limit: 20,
    p_tag: activeTag.value,
  })
}

function clearTag(): void {
  router.push('/ranking')
}

watch(activeTag, fetchRankings)
onMounted(fetchRankings)
</script>
