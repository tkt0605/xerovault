<template>
  <div class="p-6 max-w-2xl mx-auto">
    <div class="mb-6">
      <h1 class="text-2xl font-bold text-zinc-900 dark:text-white">ホーム</h1>
      <p class="text-sm text-zinc-500 mt-1">参加中のスタジオからゴールを選んで進めましょう</p>
    </div>

    <div v-if="!groupStore.groups.length" class="text-center py-16 text-zinc-400">
      <p class="text-4xl mb-4">🚀</p>
      <p class="font-medium">スタジオがまだありません</p>
      <p class="text-sm mt-1">左のサイドバーから作成してください</p>
    </div>

    <div v-else class="space-y-4">
      <div v-for="g in groupStore.groups" :key="g.id"
        class="bg-white dark:bg-zinc-900 rounded-2xl border border-zinc-200 dark:border-zinc-800 p-5 hover:shadow-md transition cursor-pointer"
        @click="router.push(`/studio/${g.id}`)">
        <div class="flex items-center justify-between mb-3">
          <h2 class="font-bold text-zinc-900 dark:text-white">{{ g.name }}</h2>
          <div class="flex items-center gap-2">
            <span v-if="g.streak >= 3" class="text-xs px-2 py-0.5 rounded-full bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-400 font-medium">
              🔥 {{ g.streak }}連続
            </span>
            <span class="text-lg font-extrabold text-brand-500">{{ g.score }}<span class="text-xs font-normal text-zinc-400 ml-0.5">pt</span></span>
          </div>
        </div>
        <div class="flex items-center gap-4 text-xs text-zinc-500">
          <span>{{ g.members.length }}人</span>
          <span>{{ g._count.goals }}ゴール</span>
          <span v-if="g.tag">#{{ g.tag }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useGroupStore } from '@/stores/group'

const router = useRouter()
const groupStore = useGroupStore()
</script>
