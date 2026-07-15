<template>
  <div class="p-6 max-w-2xl mx-auto">
    <h1 class="text-2xl font-bold mb-6 text-zinc-900 dark:text-white">スコアランキング</h1>
    <p class="text-sm text-zinc-500 mb-6">公開中の全グループの合意スコアランキングです</p>

    <div class="space-y-3">
      <div
        v-for="(g, i) in groups"
        :key="g.id"
        class="flex items-center gap-4 bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-4"
      >
        <div
          class="w-8 text-center font-extrabold"
          :class="
            i === 0
              ? 'text-yellow-500'
              : i === 1
                ? 'text-zinc-400'
                : i === 2
                  ? 'text-orange-400'
                  : 'text-zinc-300'
          "
        >
          {{ i + 1 }}
        </div>
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <p class="font-bold text-zinc-900 dark:text-white truncate">{{ g.name }}</p>
            <span v-if="g.streak >= 3" class="text-xs text-orange-500">🔥{{ g.streak }}</span>
          </div>
          <p class="text-xs text-zinc-400">
            {{ g._count.members }}人 · {{ g._count.goals }}ゴール<span v-if="g.tag">
              · #{{ g.tag }}</span
            >
          </p>
        </div>
        <p class="text-xl font-extrabold text-brand-500 shrink-0">
          {{ g.score }}<span class="text-xs font-normal text-zinc-400 ml-0.5">pt</span>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { api } from '@/api/client'

interface RankGroup {
  id: string
  name: string
  tag: string | null
  score: number
  streak: number
  _count: { members: number; goals: number }
}

const groups = ref<RankGroup[]>([])
onMounted(async () => {
  groups.value = await api.get<RankGroup[]>('/rankings')
})
</script>
