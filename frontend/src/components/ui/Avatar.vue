<template>
  <span
    class="inline-flex shrink-0 items-center justify-center rounded-full font-serif font-medium text-paper-raised"
    :style="{
      width: `${size}px`,
      height: `${size}px`,
      fontSize: `${Math.round(size * 0.4)}px`,
      backgroundColor: color,
    }"
  >
    {{ initial }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{ name: string; size?: number }>(), { size: 32 })

// 落ち着いたトーンに固定した5色から、名前のハッシュで決定的に選ぶ（dicebearのランダム多色identiconの代替）
const PALETTE = ['#7C8A82', '#A6803D', '#5B7C8A', '#8A6E8A', '#7A8A5B']

const initial = computed(() => (props.name?.trim()?.[0] ?? '?').toUpperCase())

const color = computed(() => {
  let hash = 0
  for (const ch of props.name ?? '') hash = (hash * 31 + ch.charCodeAt(0)) >>> 0
  return PALETTE[hash % PALETTE.length]
})
</script>
