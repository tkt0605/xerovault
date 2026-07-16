<template>
  <svg
    viewBox="0 0 24 24"
    :width="size"
    :height="size"
    fill="none"
    stroke="currentColor"
    stroke-width="1.8"
    stroke-linecap="round"
    stroke-linejoin="round"
    class="shrink-0"
    v-html="paths[name]"
  />
</template>

<script setup lang="ts">
withDefaults(defineProps<{ name: IconName; size?: number }>(), { size: 16 })

export type IconName =
  | 'check'
  | 'x'
  | 'alert'
  | 'flame'
  | 'plus'
  | 'chevron-left'
  | 'send'
  | 'pending'
  | 'target'
  | 'users'
  | 'logout'
  | 'copy'
  | 'home'
  | 'ranking'
  | 'menu'
  | 'edit'
  | 'trash'
  | 'bell'

const paths: Record<IconName, string> = {
  menu: '<path d="M3 6h18M3 12h18M3 18h18"/>',
  home: '<path d="m3 10.5 9-7.5 9 7.5"/><path d="M5 9v11a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V9"/>',
  ranking: '<path d="M4 20v-6"/><path d="M12 20V4"/><path d="M20 20v-9"/>',
  check: '<path d="M20 6 9 17l-5-5"/>',
  x: '<path d="M18 6 6 18M6 6l12 12"/>',
  alert: '<circle cx="12" cy="12" r="9"/><path d="M12 7v6M12 16h.01"/>',
  flame:
    '<path d="M12 2c1 4-3 5-3 9a3 3 0 0 0 6 0c0-2-1-3-1-5 2 1 3 3 3 6a5 5 0 0 1-10 0c0-5 4-6 5-10Z"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  'chevron-left': '<path d="m15 18-6-6 6-6"/>',
  send: '<path d="M22 2 11 13"/><path d="M22 2 15 22l-4-9-9-4Z"/>',
  pending: '<circle cx="12" cy="12" r="9"/>',
  target:
    '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5"/><circle cx="12" cy="12" r="1" fill="currentColor"/>',
  users:
    '<path d="M17 21v-2a4 4 0 0 0-4-4H7a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/>',
  logout:
    '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><path d="M16 17l5-5-5-5"/><path d="M21 12H9"/>',
  copy: '<rect x="9" y="9" width="12" height="12" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/>',
  edit: '<path d="M17 3a2.85 2.83 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5Z"/><path d="m15 5 4 4"/>',
  trash:
    '<path d="M3 6h18"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2"/>',
  bell: '<path d="M6 8a6 6 0 0 1 12 0c0 4 1.5 6 2 6.5H4C4.5 14 6 12 6 8Z"/><path d="M10 19a2 2 0 0 0 4 0"/>',
}
</script>
