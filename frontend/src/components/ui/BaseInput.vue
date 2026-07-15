<template>
  <input
    v-model="model"
    class="w-full rounded-control border border-line bg-paper-raised px-4 py-2.5 text-ink placeholder:text-ink-faint transition-colors focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
  />
</template>

<script setup lang="ts">
const model = defineModel<string | number>()
</script>
