<template>
  <aside class="w-72 min-h-screen bg-white dark:bg-zinc-900 border-r dark:border-zinc-700 p-4 flex flex-col gap-6">
    <!-- 操作ボタン -->
    <div class="flex flex-col gap-3">
      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-gray-800 bg-gray-200 hover:bg-gray-300 dark:bg-zinc-700 dark:text-white dark:hover:bg-zinc-600 rounded transition">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        探す
      </button>
      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-blue-600 hover:bg-blue-700 rounded transition"
        @click="GroupDailog()">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"></path>
        </svg>
        新しいスタジオ
      </button>
      <Dialog :visible="openGroupDailog" @close="openGroupDailog = false">
        <template #header>
          <h2 class="text-xl font-bold">スタジオ新規作成</h2>
        </template>
        <template #default>
          <div class="space-y-4">
            <div>
              <input id="group-name" type="text" placeholder="スタジオ名を入力" v-model="groupName"
                class="mt-1 block w-full rounded-md bg-gray-800 border border-gray-600 text-white p-2" />
            </div>
            <div>
              <label for="lib-tags" class="block text-sm font-semibold text-gray-200">タグ（カンマ区切り）</label>
              <input id="lib-tags" type="text" placeholder="例：機密, AI, レポート" v-model="groupTag"
                class="mt-1 block w-full bg-gray-800 border border-gray-600 text-white p-2 rounded-md" />
            </div>
            <div>
              <span class="block text-sm font-medium text-gray-200 mb-1">公開設定</span>
              <div class="flex items-center gap-6">
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-green-500" v-model="is_group"
                    :value="true" />
                  <span class="ml-2 text-gray-200">公開</span>
                </label>
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-red-500" v-model="is_group"
                    :value="false" />
                  <span class="ml-2 text-gray-200">非公開</span>
                </label>
              </div>
            </div>
          </div>

        </template>
        <template #footer>
          <button @click="createNewGroup()" class="bg-blue-600 text-white px-4 py-2 rounded">作成する</button>
        </template>
      </Dialog>
      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-green-600 hover:bg-green-700 rounded transition"
        @click="LibraryDailog">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round"
            d="M12 4v16m8-8H4m3-6h10a2 2 0 012 2v10a2 2 0 01-2 2H7a2 2 0 01-2-2V8a2 2 0 012-2z" />
        </svg>
        ライブラリ新規作成
      </button>
      <Dialog :visible="openLibraryDailog" @close="openLibraryDailog = false">
        <template #header>
          <h2 class="text-xl font-bold">ライブラリ新規作成</h2>
        </template>
        <template #default>
          <div class="space-y-5">
            <!-- ライブラリ名 -->
            <div>
              <label for="lib-name" class="block text-sm font-semibold text-gray-200">ライブラリ名 <span
                  class="text-red-400">*</span></label>
              <input id="lib-name" type="text" placeholder="例：研究資料2025"
                class="mt-1 block w-full bg-gray-800 border border-gray-600 text-white p-2 rounded-md" />
            </div>

            <!-- 説明 -->
            <div>
              <label for="lib-description" class="block text-sm font-semibold text-gray-200">説明</label>
              <textarea id="lib-description" rows="4" placeholder="このライブラリの目的や詳細..."
                class="mt-1 block w-full bg-gray-800 border border-gray-600 text-white p-2 rounded-md"></textarea>
            </div>

            <!-- タグ -->
            <div>
              <label for="lib-tags" class="block text-sm font-semibold text-gray-200">タグ（カンマ区切り）</label>
              <input id="lib-tags" type="text" placeholder="例：機密, AI, レポート"
                class="mt-1 block w-full bg-gray-800 border border-gray-600 text-white p-2 rounded-md" />
            </div>

            <!-- 公開設定 -->
            <div>
              <label class="block text-sm font-semibold text-gray-200">公開設定</label>
              <div class="mt-2 flex gap-6">
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" value="public" class="form-radio text-green-500" />
                  <span class="ml-2 text-gray-200">公開</span>
                </label>
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" value="private" class="form-radio text-red-500" />
                  <span class="ml-2 text-gray-200">非公開</span>
                </label>
              </div>
            </div>
          </div>

        </template>
        <template #footer>
          <button @click="openLibraryDailog = false" class="bg-green-600 text-white px-4 py-2 rounded">作成する</button>
        </template>
      </Dialog>
      <button
        class="w-full flex items-center gap-2 px-4 py-2 text-sm font-semibold text-white bg-purple-600 hover:bg-purple-700 rounded transition"
        @click="TokenDialog">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24"
          xmlns="http://www.w3.org/2000/svg">
          <path stroke-linecap="round" stroke-linejoin="round" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        トークン新規作成
      </button>
      <Dialog :visible="openTokenDailog" @close="openTokenDailog = false">
        <template #header>
          <h2 class="text-xl font-bold">トークン新規作成</h2>
        </template>
        <template #default>
          <div class="space-y-5">
            <!-- 対象スタジオ -->
            <div>
              <label for="target-group" class="block text-sm font-semibold text-gray-200">対象スタジオ</label>
              <select id="target-group" v-model="selectedGroup"
                class="mt-1 w-full bg-gray-800 text-white border border-gray-600 p-2 rounded-md">
                <option value="">選択してください</option>
                <option v-for="group in groupList" :key="group.id" :value="group.id">
                  {{ group.name }}
                </option>
              </select>
            </div>

            <!-- 備考（モデルにはないがUI補助） -->
            <div>
              <label for="note" class="block text-sm font-semibold text-gray-200">メモ（任意）</label>
              <textarea id="note" v-model="note" rows="2" placeholder="このトークンの目的などを記入..."
                class="mt-1 w-full bg-gray-800 text-white border border-gray-600 p-2 rounded-md"></textarea>
            </div>
          </div>
        </template>
        <template #footer>
          <button @click="createGroup"
            class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md">作成する</button>
        </template>
      </Dialog>
    </div>

    <!-- スタジオ一覧 -->
    <div>
      <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">スタジオ一覧</h2>
      <div class="flex flex-col gap-2">
        <div v-for="group in groups" :key="group.id"
          class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
          <NuxtLink :to="`/studio/${group.id}`">
            {{ group.name }}
          </NuxtLink>
        </div>
      </div>
    </div>

    <!-- マイ・ライブラリ -->
    <div>
      <h2 class="text-xs text-gray-500 dark:text-gray-400 tracking-widest mb-2">マイ・ライブラリ</h2>
      <div class="flex flex-col gap-2">
        <div v-for="mylib in libraries" :key="mylib.id"
          class="px-4 py-2 rounded hover:bg-gray-100 dark:hover:bg-zinc-700 cursor-pointer transition">
          {{ mylib.name }}
        </div>
      </div>
    </div>
  </aside>
</template>

<script setup>
import Dialog from '~/components/MainDialog.vue';
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
const openGroupDailog = ref(false);
const openLibraryDailog = ref(false);
const openTokenDailog = ref(false);
const groupStore = useAuthGroups();
const authStore = useAuthStore();
const currentUser = computed(() => authStore.currentUser);
const groupName = ref("");
const groupDescription = ref("");
const groupTag = ref("");
const is_group = ref(false);
const groupList = ref([]);
const libraries = ref([]);
const router = useRouter();

onMounted(async () => {
  try {
    groupList.value = await groupStore.fetchGroup();
  } catch (error) {

  }
})

const GroupDailog = () => {
  openGroupDailog.value = true
};
const LibraryDailog = () => {
  openLibraryDailog.value = true;
};
const TokenDialog = () => {
  openTokenDailog.value = true
};

const createNewGroup = async () => {
  const user = authStore?.user;
  if (!user) {
    alert('ログインしてください。');
    return;
  }
  const GroupName = groupName.value.trim();
  const Tag = groupTag.value.trim();
  const members = [user.email];
  const visibility = is_group.value;
  if (!GroupName) {
    alert('スタジオ名を入力してください。');
    return;
  }
  try {
    openGroupDailog.value = false;
    const createG = await groupStore.CreateGroup(
      GroupName,
      visibility,
      members,
      Tag
    );
    groupList.value = await groupStore.fetchGroup();
    console.log('Studioが作成されました。');
    return router.push(`/studio/${createG.id}`);
  } catch (error) {
    console.error('スタジオ作成失敗：', error);
    throw error;
  }
};
const groups = computed(() =>
  groupList.value.filter((item) => item.owner === authStore.user.email)
);
</script>
