<template>
  <Teleport to="body">
    <Transition name="achievement">
      <div
        v-if="show"
        class="fixed inset-0 z-50 flex items-center justify-center pointer-events-none"
      >
        <div
          class="bg-white dark:bg-zinc-900 rounded-3xl p-8 text-center shadow-2xl border-2 border-green-400 pointer-events-auto max-w-sm w-full mx-4"
        >
          <div class="text-6xl mb-4 animate-bounce">🏆</div>
          <h2 class="text-2xl font-extrabold text-green-500 mb-2">ゴール達成！</h2>
          <p class="text-zinc-600 dark:text-zinc-400 text-sm mb-1">全員が納得した</p>
          <p class="font-bold text-lg text-zinc-900 dark:text-white mb-4">「{{ goalHeader }}」</p>
          <div class="flex items-center justify-center gap-2 text-brand-500 font-bold text-xl mb-6">
            <span>+{{ pointsEarned }}pt</span>
            <span class="text-zinc-400 text-base font-normal">スコア獲得</span>
          </div>
          <button
            class="px-8 py-2 rounded-full bg-green-500 text-white font-medium hover:bg-green-600 transition"
            @click="$emit('close')"
          >
            閉じる
          </button>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
defineProps<{ show: boolean; goalHeader: string; pointsEarned: number }>()
defineEmits<{ close: [] }>()
</script>

<style scoped>
.achievement-enter-active {
  animation: pop 0.4s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.achievement-leave-active {
  animation: pop 0.2s ease-in reverse;
}
@keyframes pop {
  from {
    opacity: 0;
    transform: scale(0.5);
  }
  to {
    opacity: 1;
    transform: scale(1);
  }
}
</style>
