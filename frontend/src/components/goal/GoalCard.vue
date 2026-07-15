<template>
  <button
    class="w-full rounded-surface border border-line bg-paper-raised p-4 text-left transition-shadow hover:shadow-card"
    @click="$emit('click')"
  >
    <div class="flex items-start gap-3">
      <Avatar :name="goal.assignee?.name ?? goal.assignee?.email ?? '?'" :size="40" />
      <div class="min-w-0 flex-1">
        <div class="mb-2 flex items-center gap-2">
          <h3 class="truncate font-semibold text-ink">{{ goal.header || '見出しなし' }}</h3>
          <Badge v-if="goal.status === 'completed'" variant="good">
            <Icon name="check" :size="11" />
            達成
          </Badge>
          <Badge v-else-if="goal.status === 'missed'" variant="bad">
            <Icon name="alert" :size="11" />
            期限切れ
          </Badge>
          <Badge v-else-if="goal.isConcrete" variant="info">具体的</Badge>
        </div>

        <!-- 進捗バー -->
        <div class="mb-2 h-[5px] overflow-hidden rounded-full bg-paper-sunken">
          <div
            class="h-full rounded-full transition-all duration-500"
            :class="progressClass"
            :style="{ width: `${goal.progress}%` }"
          />
        </div>
        <div class="flex items-center justify-between text-xs text-ink-faint">
          <span>投票 {{ goal.progress }}%</span>
          <span v-if="goal.deadline">締切 {{ formatDate(goal.deadline) }}</span>
          <span v-else>締切なし</span>
        </div>
      </div>
    </div>
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { Goal } from '@/stores/goal'
import Avatar from '@/components/ui/Avatar.vue'
import Badge from '@/components/ui/Badge.vue'
import Icon from '@/components/ui/Icon.vue'

const props = defineProps<{ goal: Goal }>()
defineEmits<{ click: [] }>()

const progressClass = computed(() => {
  if (props.goal.progress >= 90) return 'bg-good'
  if (props.goal.progress >= 50) return 'bg-accent'
  return 'bg-bad'
})

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' })
}
</script>
