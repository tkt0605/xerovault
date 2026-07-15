<template>
  <component
    :is="tag"
    class="rounded-surface border border-line bg-paper-raised"
    :class="[padded ? 'p-5' : '', hoverable ? 'transition-shadow hover:shadow-card' : '']"
  >
    <slot />
  </component>
</template>

<script setup lang="ts">
withDefaults(defineProps<{ tag?: string; padded?: boolean; hoverable?: boolean }>(), {
  tag: 'div',
  padded: true,
  hoverable: false,
})
</script>
