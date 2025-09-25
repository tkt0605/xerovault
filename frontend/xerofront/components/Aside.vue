<template>
  <!-- <aside class="hidden md:block md:fixed md:top-20 md:left-0 md:z-40 md:w-72 md:h-[calc(100vh-4rem)] md:overflow-y-auto
         bg-white dark:bg-black border-r dark:border-zinc-700 px-4 py-2 flex flex-col gap-6" -->
  <aside class="hidden sm:flex flex-col h-screen" :class="[
    'bg-white dark:bg-zinc-900 border-r border-gray-200 dark:border-zinc-700 transition-all duration-300 ease-in-out',
    isAsideOpen ? 'w-64' : 'w-14']" v-if="isAsideOpen">
    <div class="flex flex-col mb-4">
      <button
        class="w-full flex items-center gap-2 px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('search-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        探す
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
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M12 4v16m8-8H4m3-6h10a2 2 0 012 2v10a2 2 0 01-2 2H7a2 2 0 01-2-2V8a2 2 0 012-2z" />
        </svg>
        ライブラリ新規作成
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
  <aside v-else class="hidden sm:flex flex-col h-screen" :class="[
    'bg-white dark:bg-zinc-900 border-r border-gray-200 dark:border-zinc-700 transition-all duration-300 ease-in-out',
    isAsideOpen ? 'w-64' : 'w-14']">
    <div class="flex flex-col m-1 p-1">
      <button
        class="w-10 h-10 flex items-center px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('search-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      </button>
      <button
        class="w-10 h-10 flex items-center px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('Group-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"></path>
        </svg>
      </button>
      <button
        class="w-10 h-10 flex items-center px-2 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition"
        @click="$emit('Library-dialog')">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M12 4v16m8-8H4m3-6h10a2 2 0 012 2v10a2 2 0 01-2 2H7a2 2 0 01-2-2V8a2 2 0 012-2z" />
        </svg>
      </button>
    </div>
  </aside>
  <TransitionRoot :show="props.isAsideOpen" as="template" appear>
    <Dialog as="div" class="relative z-50 sm:hidden" @close="emit('update:isAsideOpen', false)"
      :open="props.isAsideOpen" :initialFocus="initialFocus">
      <TransitionChild as="div" enter="transition-opacity duration-200" enter-from="opacity-0" enter-to="opacity-100"
        leave="transition-opacity duration-150" leave-from="opacity-100" leave-to="opacity-0">
        <div class="fixed inset-0 bg-black/30" />
      </TransitionChild>

      <div class="fixed inset-0 overflow-hidden">
        <div class="absolute inset-y-0 left-0 max-w-full flex text-black dark:text-white">
          <TransitionChild as="div" enter="transition ease-in-out duration-300 transform" enter-from="-translate-x-full"
            enter-to="translate-x-0" leave="transition ease-in-out duration-200 transform" leave-from="translate-x-0"
            leave-to="-translate-x-full">
            <DialogPanel class="w-72 h-full bg-white dark:bg-black shadow-xl p-4 overflow-y-auto"
              :initialFocus="initialFocus">
              <div class="flex justify-between mb-4">
                <button @click="goHome" class="group">
                  <div class="text-2xl font-extrabold tracking-wide bg-clip-text text-transparent 
                        bg-gradient-to-r from-purple-400 to-indigo-500 dark:from-purple-300 dark:to-blue-400
                        group-hover:from-indigo-400 group-hover:to-blue-600 transition-all duration-300 py-2 ml-3">
                    iStudio
                  </div>
                </button>
                <button @click="emit('update:isAsideOpen', false)" class="text-zinc-800 dark:text-white">
                  <svg class="w-6 h-6" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
              <div class="flex flex-col mb-4">
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
                  <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
                    xmlns="http://www.w3.org/2000/svg">
                    <path stroke-linecap="round" stroke-linejoin="round"
                      d="M12 4v16m8-8H4m3-6h10a2 2 0 012 2v10a2 2 0 01-2 2H7a2 2 0 01-2-2V8a2 2 0 012-2z" />
                  </svg>
                  ライブラリ新規作成
                </button>
              </div>
              <div>
                <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">スタジオ一覧</h2>
                <div v-for="group in groupList" :key="group.id" class="flex flex-col gap-2">
                  <NuxtLink :to="`/studio/${group.id}`" @click="emit('update:isAsideOpen', false)">
                    <div class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
                      # {{ group.name }}
                    </div>
                  </NuxtLink>
                </div>
              </div>
              <div class="mt-6">
                <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">マイ・ライブラリ</h2>
                <div v-for="mylib in libraryList" :key="mylib.id" class="flex flex-col gap-2">
                  <NuxtLink :to="`/library/${mylib.id}`" @click="emit('update:isAsideOpen', false)">
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
  <!-- <TransitionRoot>
    <Dialog>
      <TransitionChild>

      </TransitionChild>
      <div>
        <div>
          <TransitionChild>
            <DialogPanel></DialogPanel>
          </TransitionChild>
        </div>
      </div>
    </Dialog>
  </TransitionRoot> -->
</template>
<script setup>
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useAuthLibrary } from '~/store/library';
import { ref, onMounted, inject } from 'vue';
import { Disclosure } from '@headlessui/vue';
import { Dialog, DialogPanel, TransitionRoot, TransitionChild } from '@headlessui/vue';
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

const initialFocus = ref(null);
const groupStore = useAuthGroups();
const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const groupList = ref([]);
const libraries = ref([]);
onMounted(async () => {
  try {
    groupList.value = await groupStore.fetchGroup();
    console.log('グループ一覧:', groupList.value);
    libraries.value = await libraryStore.FetchLibrary();
  } catch (error) {

  }
});

const groups = computed(() => {
  if (!groupList.value || !Array.isArray(groupList.value.members) || !authStore.currentUser)
    return false;
  // return groupList.value.members.some(member => member.email === authStore.user.email);
});
const libraryList = computed(() =>
  libraries.value.filter((item) => item.owner === authStore.user.email)
);
</script>
