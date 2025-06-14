<template>
  <div class="flex flex-col min-h-screen bg-gray-50 dark:bg-zinc-800 text-gray-800 dark:text-white">

    <!-- ヘッダー：上部固定 -->
    <header class="shadow bg-white dark:bg-zinc-900 sticky top-0 z-50">
      <Header />
    </header>

    <!-- メインコンテンツ：サイドバー＋本文 -->
    <div class="flex flex-1 overflow-hidden">
      <!-- サイドバー -->
      <!-- <aside class="w-64 bg-white dark:bg-zinc-900 border-r border-gray-200 dark:border-zinc-700 p-4 overflow-y-auto hidden md:block"> -->
      <aside>
        <Aside />
      </aside>

      <!-- メインビュー -->
      <main class="flex-1 p-6 overflow-y-auto">
        <Main />
      </main>
    </div>
  </div>
</template>

<script setup>
import Header from '~/components/Header.vue';
import Aside from '~/components/Aside.vue';
import Main from '~/components/Main.vue';
import '~/assets/css/index.css';
</script>
