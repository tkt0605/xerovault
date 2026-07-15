<template>
  <Teleport to="body">
    <Transition name="achievement">
      <div
        v-if="show"
        class="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-ink/30"
      >
        <div
          class="pointer-events-auto mx-4 w-full max-w-sm rounded-surface border border-line bg-paper-raised p-8 text-center shadow-modal"
        >
          <div
            class="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-full bg-good-soft"
          >
            <Icon name="check" :size="26" class="text-good" />
          </div>
          <h2 class="mb-1 font-serif text-xl font-medium text-ink">ゴール達成</h2>
          <p class="mb-1 text-sm text-ink-soft">全員が納得しました</p>
          <p class="mb-4 text-lg font-semibold text-ink">「{{ goalHeader }}」</p>
          <div class="mb-6 font-serif text-2xl text-accent">+{{ pointsEarned }}pt</div>
          <BaseButton @click="$emit('close')">閉じる</BaseButton>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import Icon from '@/components/ui/Icon.vue'
import BaseButton from '@/components/ui/BaseButton.vue'

defineProps<{ show: boolean; goalHeader: string; pointsEarned: number }>()
defineEmits<{ close: [] }>()
</script>

<style scoped>
.achievement-enter-active {
  transition:
    opacity 0.2s ease,
    transform 0.2s cubic-bezier(0.2, 0.8, 0.2, 1);
}
.achievement-leave-active {
  transition:
    opacity 0.15s ease,
    transform 0.15s ease;
}
.achievement-enter-from,
.achievement-leave-to {
  opacity: 0;
  transform: scale(0.96);
}
</style>
