<template>
  <button @click="$emit('click')" class="w-full text-left group bg-white dark:bg-zinc-800 rounded-2xl border border-zinc-200 dark:border-zinc-700 p-4 hover:shadow-md transition-all">
    <div class="flex items-start gap-3">
      <img :src="goal.assignee?.avatar ?? defaultAvatar" class="w-10 h-10 rounded-full object-cover ring-2 ring-white dark:ring-zinc-700 shrink-0" />
      <div class="flex-1 min-w-0">
        <div class="flex items-center gap-2 mb-1">
          <h3 class="font-semibold text-zinc-900 dark:text-white truncate">{{ goal.header || '見出しなし' }}</h3>
          <span v-if="goal.isCompleted" class="shrink-0 text-xs px-2 py-0.5 rounded-full bg-green-100 text-green-700 dark:bg-green-900/40 dark:text-green-300 font-medium">
            達成
          </span>
          <span v-else-if="goal.isConcrete" class="shrink-0 text-xs px-2 py-0.5 rounded-full bg-blue-100 text-blue-700 dark:bg-blue-900/40 dark:text-blue-300">
            具体的
          </span>
        </div>

        <!-- 進捗バー -->
        <div class="h-2 rounded-full bg-zinc-100 dark:bg-zinc-700 overflow-hidden mb-2">
          <div class="h-full rounded-full transition-all duration-500"
            :class="progressClass"
            :style="{ width: `${goal.progress}%` }" />
        </div>
        <div class="flex items-center justify-between text-xs text-zinc-500 dark:text-zinc-400">
          <span>投票 {{ goal.progress }}%</span>
          <span v-if="goal.deadline">締切 {{ formatDate(goal.deadline) }}</span>
          <span v-else class="text-zinc-400">締切なし</span>
        </div>
      </div>
    </div>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { Goal } from '@/stores/goal'

const props = defineProps<{ goal: Goal }>()
defineEmits<{ click: [] }>()

const defaultAvatar = `https://api.dicebear.com/9.x/identicon/svg?seed=default`

const progressClass = computed(() => {
  if (props.goal.progress >= 90) return 'bg-green-500'
  if (props.goal.progress >= 50) return 'bg-yellow-500'
  return 'bg-red-400'
})

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' })
}
</script>
