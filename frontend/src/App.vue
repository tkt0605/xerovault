<template>
  <div class="min-h-screen bg-white dark:bg-zinc-950 text-zinc-900 dark:text-zinc-100">
    <component :is="layout">
      <RouterView />
    </component>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import AuthLayout from '@/components/layout/AuthLayout.vue'

const route = useRoute()
const layout = computed(() =>
  route.path.startsWith('/auth') ? AuthLayout : DefaultLayout
)
</script>
