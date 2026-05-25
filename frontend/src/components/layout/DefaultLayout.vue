<template>
  <div class="flex h-screen overflow-hidden">
    <Aside />
    <main class="flex-1 overflow-y-auto">
      <Header />
      <slot />
    </main>
  </div>
</template>

<script setup lang="ts">
import Aside from './Aside.vue'
import Header from './Header.vue'
</script>
