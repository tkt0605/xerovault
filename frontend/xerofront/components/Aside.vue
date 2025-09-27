<template>
  <!-- <aside class="hidden md:block md:fixed md:top-20 md:left-0 md:z-40 md:w-72 md:h-[calc(100vh-4rem)] md:overflow-y-auto
         bg-white dark:bg-black border-r dark:border-zinc-700 px-4 py-2 flex flex-col gap-6" -->
  <aside class="hidden sm:flex flex-col h-screen p-2" :class="[
    'bg-white dark:bg-zinc-900 border-r P-4 border-gray-200 dark:border-zinc-700 transition-all duration-300 ease-in-out',
    !isSabAsideOpen ? 'w-64' : 'w-14']" v-if="!isSabAsideOpen">
    <div class="flex flex-col mb-4 gap-2">
      <button
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('search-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        <span>探す</span>
      </button>
      <button @click="goHome"
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5" viewBox="0 0 16 16">
          <path
            d="M8.707 1.5a1 1 0 0 0-1.414 0L.646 8.146a.5.5 0 0 0 .708.708L2 8.207V13.5A1.5 1.5 0 0 0 3.5 15h9a1.5 1.5 0 0 0 1.5-1.5V8.207l.646.647a.5.5 0 0 0 .708-.708L13 5.793V2.5a.5.5 0 0 0-.5-.5h-1a.5.5 0 0 0-.5.5v1.293zM13 7.207V13.5a.5.5 0 0 1-.5.5h-9a.5.5 0 0 1-.5-.5V7.207l5-5z" />
        </svg>
        <span>ホーム</span>
      </button>
      <button
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('Group-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"></path>
        </svg>
        <span>新しいスタジオ</span>
      </button>
      <button
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('Library-dialog')">
        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5" viewBox="0 0 16 16">
          <path
            d="M5 0h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2 2 2 0 0 1-2 2H3a2 2 0 0 1-2-2h1a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1H1a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v9a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1H3a2 2 0 0 1 2-2" />
          <path
            d="M1 6v-.5a.5.5 0 0 1 1 0V6h.5a.5.5 0 0 1 0 1h-2a.5.5 0 0 1 0-1zm0 3v-.5a.5.5 0 0 1 1 0V9h.5a.5.5 0 0 1 0 1h-2a.5.5 0 0 1 0-1zm0 2.5v.5H.5a.5.5 0 0 0 0 1h2a.5.5 0 0 0 0-1H2v-.5a.5.5 0 0 0-1 0" />
        </svg>
        <span>新しいライブラリ</span>
      </button>
    </div>

    <div>
      <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">スタジオ一覧</h2>
      <div v-for="group in groupList" :key="group.id" class="flex flex-col gap-2">
        <NuxtLink :to="`/studio/${group.id}`">
          <div class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
            # {{ group.name }}
          </div>
        </NuxtLink>
      </div>
    </div>

    <div>
      <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">マイ・ライブラリ</h2>
      <div v-for="mylib in libraryList" :key="mylib.id" class="flex flex-col gap-2">
        <NuxtLink :to="`/library/${mylib.id}`">
          <div class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
            {{ mylib.name }}
          </div>
        </NuxtLink>
      </div>
    </div>
  </aside>
  <aside class="hidden sm:flex flex-col h-screen py-2.5 px-2" :class="[
    'bg-white dark:bg-zinc-900 border-r P-4 border-gray-200 dark:border-zinc-700 transition-all duration-300 ease-in-out',
    isSabAsideOpen, 'w-14']" v-else>
    <div class="flex flex-col mb-4 gap-3">
      <button
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('search-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </button>
      <button @click="goHome"
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5" viewBox="0 0 16 16">
          <path
            d="M8.707 1.5a1 1 0 0 0-1.414 0L.646 8.146a.5.5 0 0 0 .708.708L2 8.207V13.5A1.5 1.5 0 0 0 3.5 15h9a1.5 1.5 0 0 0 1.5-1.5V8.207l.646.647a.5.5 0 0 0 .708-.708L13 5.793V2.5a.5.5 0 0 0-.5-.5h-1a.5.5 0 0 0-.5.5v1.293zM13 7.207V13.5a.5.5 0 0 1-.5.5h-9a.5.5 0 0 1-.5-.5V7.207l5-5z" />
        </svg>
      </button>
      <button
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('Group-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"></path>
        </svg>
      </button>
      <button
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('Library-dialog')">
        <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5" viewBox="0 0 16 16">
          <path
            d="M5 0h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2 2 2 0 0 1-2 2H3a2 2 0 0 1-2-2h1a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1H1a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v9a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1H3a2 2 0 0 1 2-2" />
          <path
            d="M1 6v-.5a.5.5 0 0 1 1 0V6h.5a.5.5 0 0 1 0 1h-2a.5.5 0 0 1 0-1zm0 3v-.5a.5.5 0 0 1 1 0V9h.5a.5.5 0 0 1 0 1h-2a.5.5 0 0 1 0-1zm0 2.5v.5H.5a.5.5 0 0 0 0 1h2a.5.5 0 0 0 0-1H2v-.5a.5.5 0 0 0-1 0" />
        </svg>
      </button>
    </div>
  </aside>
  <TransitionRoot :show="props.isAsideOpen" as="template" appear>
    <Dialog as="div" class="relative z-50 sm:hidden" @close="clickAsideOpen" :open="props.isAsideOpen"
    >
      <TransitionChild as="div" enter="transition-opacity duration-200" enter-from="opacity-0" enter-to="opacity-100"
        leave="transition-opacity duration-150" leave-from="opacity-100" leave-to="opacity-0">
        <div class="fixed inset-0 bg-black/30" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-y-0 left-0 max-w-full flex text-black dark:text-white">
          <TransitionChild as="div" enter="transition ease-in-out duration-300 transform" enter-from="-translate-x-full"
            enter-to="translate-x-0" leave="transition ease-in-out duration-200 transform" leave-from="translate-x-0"
            leave-to="-translate-x-full">
            <DialogPanel ref="initialFocus"
              class="w-72 h-full bg-white dark:bg-black shadow-xl p-4 overflow-y-auto">
              <div class="flex justify-between mb-4">
                <button @click="goHome" class="group">
                  <div class="text-2xl font-extrabold tracking-wide bg-clip-text text-transparent 
                        bg-gradient-to-r from-purple-400 to-indigo-500 dark:from-purple-300 dark:to-blue-400
                        group-hover:from-indigo-400 group-hover:to-blue-600 transition-all duration-300 py-2 ml-3">
                    iStudio
                  </div>
                </button>
                <button @click="clickAsideOpen" class="text-zinc-800 dark:text-white">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div class="flex flex-col mb-4 gap-2">
                <button
                  class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
                  @click="$emit('search-dialog')">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                  </svg>
                  探す
                </button>
                <button @click="goHome"
                  class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5" viewBox="0 0 16 16">
                    <path
                      d="M8.707 1.5a1 1 0 0 0-1.414 0L.646 8.146a.5.5 0 0 0 .708.708L2 8.207V13.5A1.5 1.5 0 0 0 3.5 15h9a1.5 1.5 0 0 0 1.5-1.5V8.207l.646.647a.5.5 0 0 0 .708-.708L13 5.793V2.5a.5.5 0 0 0-.5-.5h-1a.5.5 0 0 0-.5.5v1.293zM13 7.207V13.5a.5.5 0 0 1-.5.5h-9a.5.5 0 0 1-.5-.5V7.207l5-5z" />
                  </svg>
                  <span>ホーム</span>
                </button>
                <button
                  class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
                  @click="$emit('Group-dialog')">
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"></path>
                  </svg>
                  新しいスタジオ
                </button>
                <button
                  class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
                  @click="$emit('Library-dialog')">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="currentColor" class="w-5 h-5" viewBox="0 0 16 16">
                    <path
                      d="M5 0h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2 2 2 0 0 1-2 2H3a2 2 0 0 1-2-2h1a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4a1 1 0 0 0-1-1H3a1 1 0 0 0-1 1H1a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v9a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1H5a1 1 0 0 0-1 1H3a2 2 0 0 1 2-2" />
                    <path
                      d="M1 6v-.5a.5.5 0 0 1 1 0V6h.5a.5.5 0 0 1 0 1h-2a.5.5 0 0 1 0-1zm0 3v-.5a.5.5 0 0 1 1 0V9h.5a.5.5 0 0 1 0 1h-2a.5.5 0 0 1 0-1zm0 2.5v.5H.5a.5.5 0 0 0 0 1h2a.5.5 0 0 0 0-1H2v-.5a.5.5 0 0 0-1 0" />
                  </svg>
                  ライブラリ新規作成
                </button>
              </div>
              <div>
                <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">スタジオ一覧</h2>
                <div v-for="group in groupList" :key="group.id" class="flex flex-col gap-2">
                  <NuxtLink :to="`/studio/${group.id}`" @click="clickAsideOpen">
                    <div class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
                      # {{ group.name }}
                    </div>
                  </NuxtLink>
                </div>
              </div>
              <div class="mt-6">
                <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">マイ・ライブラリ</h2>
                <div v-for="mylib in libraryList" :key="mylib.id" class="flex flex-col gap-2">
                  <NuxtLink :to="`/library/${mylib.id}`" @click="clickAsideOpen">
                    <div class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
                      {{ mylib.name }}
                    </div>
                  </NuxtLink>
                </div>
              </div>
            </DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot>
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useAuthLibrary } from '~/store/library';
import { ref, onMounted, inject } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { Dialog, DialogPanel, TransitionRoot, TransitionChild } from '@headlessui/vue';
const route = useRoute();
const router = useRouter();
const initialFocus = ref(null);
const groupStore = useAuthGroups();
const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const groupList = ref([]);
const libraries = ref([]);
const props = defineProps({
  isOpen: {
    type: Boolean,
    default: true,
  },
  isAsideOpen: {
    type: Boolean,
    default: false
  },
  isSabAsideOpen: {
    type: Boolean,
    default: false
  }
});
const emit = defineEmits([
  'searchDialog',
  'toggleSidebar',
  'tokenDialog',
  'libraryDialog',
  'groupDialog',
  'close',
  'update:isAsideOpen',
  'update:isSabAsideOpen'
]);
const localAsideOpen = ref(props.isAsideOpen);
const localSabAsideOpen = ref(props.isSabAsideOpen);
watch(() => props.isAsideOpen, (newVal) => {
  localAsideOpen.value = newVal;
});
watch(() => props.isSabAsideOpen, (newVal) => {
  localSabAsideOpen.value = newVal;
});
onMounted(async () => {
  try {
    groupList.value = await groupStore.fetchGroup();
    console.log('グループ一覧:', groupList.value);
    libraries.value = await libraryStore.FetchLibrary();
    const isMobile = window.matchMedia('(max-width: 768px)').matches;
    console.log(isMobile);
    console.log(localAsideOpen);
    setTimeout(() => {
      initialFocus.value?.focus()
    }, 50);
  } catch (error) {

  }
});
const goHome = () => {
  const isMobile = window.matchMedia('(max-width: 768px)').matches;
  if (isMobile) {
    localAsideOpen.value = !localAsideOpen.value;
    emit('update:isAsideOpen', localAsideOpen.value);
    console.log("スマートフォン・Aside表示アクション", localAsideOpen.value);
    console.log('SP:', localAsideOpen.value);
    return router.push('/');
  } else {
    localSabAsideOpen.value = !localSabAsideOpen.value;
    emit('update:isSabAsideOpen', localSabAsideOpen.value);
    console.log("スマートフォン・Aside表示アクション", localSabAsideOpen.value);
    console.log('SP:', localSabAsideOpen.value);
    return router.push('/');
  }
};
const clickAsideOpen = () => {
  console.log('閉じるbuttonをクリック');
  const isMobile = window.matchMedia('(max-width: 768px)').matches;
  if (isMobile) {
    localAsideOpen.value = !localAsideOpen.value;
    console.log('Asideボード非表示アクション：', localAsideOpen.value);
    emit('update:isAsideOpen', localAsideOpen.value);
    console.log("スマートフォン・Aside表示アクション", localAsideOpen.value);
    console.log('SP:', localAsideOpen.value);
    console.log('スマートフォン・Aside・動作完了');
  }
};
const groups = computed(() => {
  if (!groupList.value || !Array.isArray(groupList.value.members) || !authStore.currentUser)
    return false;
  // return groupList.value.members.some(member => member.email === authStore.user.email);
});
const libraryList = computed(() =>
  libraries.value.filter((item) => item.owner === authStore.user.email)
);
</script>
