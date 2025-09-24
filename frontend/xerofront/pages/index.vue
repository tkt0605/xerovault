<!-- <template>
  <main class="text-black dark:text-white  md:ml-72 ml-0 relative flex-1 overflow-y-auto">
    <div class="relative z-10 max-w-6xl mx-auto px-6 py-16 flex flex-col items-center text-center">
      <div class="relative">
        <img :src="currentUser?.avater"
          class="w-28 h-28 rounded-full border-4 border-indigo-400 shadow-2xl object-cover" alt="オーナーのアバター" />
        <div class="absolute inset-0 rounded-full border-2 border-indigo-500 animate-spin-slow"></div>
      </div>
      <h1 class="mt-6 text-3xl font-extrabold tracking-tight">
        {{ currentUser?.email || 'オーナー名未設定' }}
      </h1>
      <span class="mt-2 text-xs text-purple-200 bg-purple-700/80 px-3 py-1 rounded-full shadow">
        ログイン・ユーザー
      </span>
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-6 mt-10 w-full text-sm">
        <button @click="$emit('Group-dialog')"
          class=" items-center justify-center p-8 rounded-2xl bg-gradient-to-r from-blue-700 to-indigo-500 shadow-lg group transition transform hover:-translate-y-1">
          <p class="font-semibold text-2xl">{{ My_Studio_Counter }}</p>
          <p>＋スタジオ</p>
          <span
            class="absolute inset-0 bg-white/20 scale-0 group-hover:scale-100 rounded-2xl transition-transform"></span>
        </button>
        <button @click="$emit('Group-dialog')"
          class="items-center justify-center p-8 rounded-2xl bg-gradient-to-r from-green-600 to-emerald-400 shadow-lg group transition transform hover:-translate-y-1">
          <p class="font-semibold text-2xl">{{ My_Library_Countrer }}</p>
          <p>＋ライブラリ</p>
          <span
            class="absolute inset-0 bg-white/20 scale-0 group-hover:scale-100 rounded-2xl transition-transform"></span>
        </button>
        <div
          class="items-center justify-center p-8 rounded-2xl bg-gradient-to-r from-red-600 to-red-800 shadow-lg group transition transform hover:-translate-y-1">
          <p class="font-semibold text-2xl">{{ My_Goal_Counter }}</p>
          <p>ゴール</p>
          <span
            class="absolute inset-0 bg-white/20 scale-0 group-hover:scale-100 rounded-2xl transition-transform"></span>
        </div>
        <div class="bg-zinc-800/60 rounded-xl p-8 shadow flex flex-col items-center relative overflow-hidden">
          <div class="absolute bottom-0 left-0 w-full bg-green-500/50 animate-pulse transition-all duration-500"
            :style="{ height: achievementRate + '%' }"></div>
          <p class="font-semibold text-2xl ">{{ achievementRate }}%</p>
          <p>今月の達成率</p>
        </div>
      </div>
      <div class="mt-12 w-full grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="bg-zinc-800 rounded-xl p-6 shadow-lg hover:rotate-1 hover:shadow-2xl transition transform">
          <h3 class="text-lg font-bold text-blue-400 mb-3">🧩 最近のスタジオ</h3>
          <ul class="space-y-2 text-left text-sm" v-if="my_studios.length === 0">
            <li class="p-2 bg-zinc-700/50 rounded">まだスタジオがありません。</li>
          </ul>
          <ul class="space-y-2 text-left text-sm" v-for="my_studio in news_studios" :key="my_studio.id" v-else>
            <li class="p-2 bg-zinc-700/50 rounded"># {{ my_studio.name }}</li>
          </ul>
        </div>
        <div class="bg-zinc-800 rounded-xl p-6 shadow-lg hover:-rotate-1 hover:shadow-2xl transition transform">
          <h3 class="text-lg font-bold text-green-400 mb-3">📚 最近のライブラリ</h3>
          <ul class="space-y-2 text-left text-sm" v-if="my_libraries.length === 0">
            <li class="p-2 bg-zinc-700/50 rounded">まだライブラリがありません。</li>
          </ul>
          <ul class="space-y-2 text-left text-sm" v-for="my_library in news_librarys" :key="my_library.id" v-else>
            <li class="p-2 bg-zinc-700/50 rounded">{{ my_library.name }}</li>
          </ul>
        </div>
      </div>
    </div>
  </main>
</template> -->
<template>
  <main class="text-black dark:text-white bg-gray-50 dark:bg-zinc-900 md:ml-72 ml-0 relative flex-1 overflow-y-auto">
    <div class="relative z-10 max-w-6xl mx-auto px-6 py-16 flex flex-col items-center text-center">
      <div class="relative">
        <img :src="currentUser?.avater"
          class="w-28 h-28 rounded-full border-4 border-indigo-400 shadow-2xl object-cover" alt="オーナーのアバター" />
        <div class="absolute inset-0 rounded-full border-2 border-indigo-500 animate-spin-slow"></div>
      </div>

      <!-- User Info -->
      <h1 class="mt-6 text-3xl font-extrabold tracking-tight">
        {{ currentUser?.email || 'オーナー名未設定' }}
      </h1>
      <span class="mt-2 text-xs text-purple-800 dark:text-purple-200 bg-purple-100 dark:bg-purple-700/80 px-3 py-1 rounded-full shadow">
        ログイン・ユーザー
      </span>

      <!-- Stats with playful animation -->
      <div class="grid grid-cols-2 sm:grid-cols-4 gap-6 mt-10 w-full text-sm">
        <!-- Studio Button -->
        <button @click="$emit('Group-dialog')"
          class="text-white dark:text-white items-center justify-center p-8 rounded-2xl bg-gradient-to-r from-blue-600 to-indigo-500 shadow-lg group transition transform hover:-translate-y-1">
          <p class="font-semibold text-2xl">{{ My_Studio_Counter }}</p>
          <p>＋スタジオ</p>
          <span
            class="absolute inset-0 bg-white/20 scale-0 group-hover:scale-100 rounded-2xl transition-transform"></span>
        </button>

        <!-- Library Button -->
        <button @click="$emit('Group-dialog')"
          class="text-white dark:text-white items-center justify-center p-8 rounded-2xl bg-gradient-to-r from-green-600 to-emerald-400 shadow-lg group transition transform hover:-translate-y-1">
          <p class="font-semibold text-2xl">{{ My_Library_Countrer }}</p>
          <p>＋ライブラリ</p>
          <span
            class="absolute inset-0 bg-white/20 scale-0 group-hover:scale-100 rounded-2xl transition-transform"></span>
        </button>

        <!-- Goal Info -->
        <div
          class="text-white dark:text-white items-center justify-center p-8 rounded-2xl bg-gradient-to-r from-red-600 to-red-800 shadow-lg group transition transform hover:-translate-y-1">
          <p class="font-semibold text-2xl">{{ My_Goal_Counter }}</p>
          <p>ゴール</p>
          <span
            class="absolute inset-0 bg-white/20 scale-0 group-hover:scale-100 rounded-2xl transition-transform"></span>
        </div>

        <!-- Achievement Rate -->
        <div class="bg-green-200/60 dark:bg-zinc-800/60 rounded-xl p-8 shadow flex flex-col items-center relative overflow-hidden">
          <div class="absolute bottom-0 left-0 w-full bg-green-500/50 animate-pulse transition-all duration-500"
            :style="{ height: achievementRate + '%' }"></div>
          <p class="font-semibold text-2xl relative z-10">{{ achievementRate }}%</p>
          <p class="relative z-10">今月の達成率</p>
        </div>
      </div>

      <!-- Recent Cards -->
      <div class="mt-12 w-full grid grid-cols-1 md:grid-cols-2 gap-6">
        
        <!-- Studio Card -->
        <div class="bg-white dark:bg-zinc-800 rounded-xl p-6 shadow-lg hover:rotate-1 hover:shadow-2xl transition transform">
          <h3 class="text-lg font-bold text-blue-600 dark:text-blue-400 mb-3">🧩 最近のスタジオ</h3>
          <ul class="space-y-2 text-left text-sm" v-if="my_studios.length === 0">
            <li class="p-2 bg-gray-100 dark:bg-zinc-700/50 rounded">まだスタジオがありません。</li>
          </ul>
          <ul class="space-y-2 text-left text-sm" v-for="my_studio in news_studios" :key="my_studio.id" v-else>
            <li class="p-2 bg-gray-100 dark:bg-zinc-700/50 rounded"># {{ my_studio.name }}</li>
          </ul>
        </div>

        <!-- Library Card -->
        <div class="bg-white dark:bg-zinc-800 rounded-xl p-6 shadow-lg hover:-rotate-1 hover:shadow-2xl transition transform">
          <h3 class="text-lg font-bold text-green-600 dark:text-green-400 mb-3">📚 最近のライブラリ</h3>
          <ul class="space-y-2 text-left text-sm" v-if="my_libraries.length === 0">
            <li class="p-2 bg-gray-100 dark:bg-zinc-700/50 rounded">まだライブラリがありません。</li>
          </ul>
          <ul class="space-y-2 text-left text-sm" v-for="my_library in news_librarys" :key="my_library.id" v-else>
            <li class="p-2 bg-gray-100 dark:bg-zinc-700/50 rounded">{{ my_library.name }}</li>
          </ul>
        </div>

      </div>
    </div>
  </main>
</template>

<style scoped>
.animate-spin-slow {
  animation: spin 20s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0);
  }

  100% {
    transform: rotate(360deg);
  }
}
</style>




<style scoped>
.stat-card {
  @apply w-5/6 sm:w-32 md:w-36 lg:w-40 rounded-full aspect-square shadow flex flex-col items-center justify-center text-white text-lg font-bold transition;
}
</style>

<script setup>
import { useAuthStore } from '~/store/auth';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { eventBus } from '~/utils/eventBus';
import { computed } from 'vue';
import { useAuthGroups } from '~/store/group';
import { useAuthLibrary } from '~/store/library';
import { useGoalStore } from '~/store/goal';
const authStore = useAuthStore();
const route = useRoute();
const router = useRouter();
const currentUser = computed(() => authStore.currentUser);
const groupStore = useAuthGroups();
const libraryStore = useAuthLibrary();
const goalStore = useGoalStore();
const my_studios = ref([]);
const my_libraries = ref([]);
const my_goals = ref([]);

onMounted(async () => {
  try {
    await authStore.restoreSession();
    const userId = authStore?.user?.id;
    my_studios.value = await groupStore.fetchGroup();
    my_libraries.value = await libraryStore.fetchMylibrary();
    my_goals.value = await goalStore.MyGoals();
  } catch (error) {
    console.error('セッションの復元中にエラーが発生しました:', error);
    throw error;
  }
})

const JampToInviting = async () => {
  return router.push(`/invite/${authStore.user.id}`);
};
function emitStudio() {
  eventBus.emit('Group-dialog');
};
function emitLibrary() {
  eventBus.emit('Library-dialog');
};
const news_studios = computed(() => {
  if (!Array.isArray(my_studios.value)) return [];
  return my_studios.value
    .slice()
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 3);
});
const news_librarys = computed(() => {
  if (!Array.isArray(my_libraries.value)) return [];
  return my_libraries.value
    .slice()
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(0, 3);
});
const My_Studio_Counter = computed(() => my_studios.value.length);
const My_Library_Countrer = computed(() => my_libraries.value.length);
const My_Goal_Counter = computed(() => my_goals.value.length);

const achievementRate = computed(() => {
  if (!Array.isArray(my_goals.value) || my_goals.value.length === 0) return  0;
  let completed = 0;
  let total = 0;
  my_goals.value.forEach(goal => {
    completed += goal.progress === 100 ?? 0;
    total += goal.progress ?? 0;
  });
  if (total ===0) return 0;
  return Math.round((completed / my_goals.value.length) * 100);
})
</script>
