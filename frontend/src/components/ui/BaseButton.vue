<template>
  <button
    :type="type"
    class="inline-flex items-center justify-center gap-1.5 rounded-control font-medium transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
    :class="[sizeClass, variantClass]"
  >
    <slot />
  </button>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    variant?: 'primary' | 'ghost' | 'outline' | 'good' | 'bad'
    size?: 'md' | 'sm'
    active?: boolean
    type?: 'button' | 'submit'
  }>(),
  { variant: 'primary', size: 'md', active: false, type: 'button' }
)

const sizeClass = computed(() =>
  props.size === 'sm' ? 'text-xs px-3 py-1.5' : 'text-sm px-4 py-2'
)

const variantClass = computed(() => {
  switch (props.variant) {
    case 'ghost':
      return 'border border-line text-ink hover:bg-paper-sunken'
    case 'outline':
      return 'border border-accent text-accent hover:bg-accent hover:text-paper-raised'
    case 'good':
      return props.active
        ? 'bg-good text-paper-raised border border-good'
        : 'border border-good text-good hover:bg-good-soft'
    case 'bad':
      return props.active
        ? 'bg-bad text-paper-raised border border-bad'
        : 'border border-bad text-bad hover:bg-bad-soft'
    default:
      return 'bg-accent text-paper-raised hover:bg-accent-strong'
  }
})
</script>
