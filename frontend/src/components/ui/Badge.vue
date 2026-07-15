<template>
  <span
    class="inline-flex shrink-0 items-center gap-1 rounded-full px-2.5 py-0.5 text-[11px] font-semibold"
    :class="variantClass"
  >
    <slot />
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{ variant?: 'good' | 'bad' | 'info' }>(), {
  variant: 'info',
})

const variantClass = computed(() => {
  switch (props.variant) {
    case 'good':
      return 'bg-good-soft text-good'
    case 'bad':
      return 'bg-bad-soft text-bad'
    default:
      return 'bg-paper-sunken text-ink-soft'
  }
})
</script>
