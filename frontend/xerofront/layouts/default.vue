<template>
  <div class="flex flex-col min-h-screen bg-gray-50 dark:bg-zinc-800 text-gray-800 dark:text-white">

    <!-- ヘッダー：上部固定 -->
    <header class="shadow bg-white dark:bg-zinc-900 sticky top-0 z-50">
      <Header @toggle-sidebar="toggleSidebar" />
    </header>

    <!-- メインコンテンツ：サイドバー＋本文 -->
    <div class="flex flex-1 overflow-hidden">
      <!-- サイドバー -->
      <aside>
        <!-- <aside class="hidden md:block"> -->
        <Aside @toggle-sidebar="toggleSidebar" @Token-dialog="TokenDialog()" @Library-dialog="LibraryDailog()"
          @Group-dialog="GroupDailog" :isOpen="isSidebarOpen" @close="isSidebarOpen = false"
          class=" overflow-y-auto hidden md:block" />
      </aside>

      <!-- メインビュー -->
      <main class="flex-1 overflow-y-auto">
        <NuxtPage />
      </main>
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
          <button @click="openGroupDailog = false"
            class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="createNewGroup()" class="bg-blue-600 text-white px-4 py-2 rounded">作成する</button>
        </template>
      </Dialog>
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
              <input id="lib-name" type="text" placeholder="例：研究資料2025" v-model="libraryName"
                class="mt-1 block w-full bg-gray-800 border border-gray-600 text-white p-2 rounded-md" />
            </div>

            <!-- タグ -->
            <div>
              <label for="lib-tags" class="block text-sm font-semibold text-gray-200">タグ（カンマ区切り）</label>
              <input id="lib-tags" type="text" v-model="libraryTag" placeholder="例：機密, AI, レポート"
                class="mt-1 block w-full bg-gray-800 border border-gray-600 text-white p-2 rounded-md" />
            </div>

            <!-- 公開設定 -->
            <div>
              <span class="block text-sm font-medium text-gray-200 mb-1">公開設定</span>
              <div class="flex items-center gap-6">
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-green-500" v-model="is_library"
                    :value="true" />
                  <span class="ml-2 text-gray-200">公開</span>
                </label>
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-red-500" v-model="is_library"
                    :value="false" />
                  <span class="ml-2 text-gray-200">非公開</span>
                </label>
              </div>
            </div>
          </div>

        </template>
        <template #footer>
          <button @click="openLibraryDailog = false"
            class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="createLibrary" class="bg-green-600 text-white px-4 py-2 rounded">作成する</button>
        </template>
      </Dialog>
      <Dialog :visible="openTokenDailog" @close="openTokenDailog = false">
        <template #header>
          <h2 class="text-xl font-bold">ユーザー・リクエスト</h2>
        </template>
        <template #default>
          <div class="space-y-5">
            <div>
              <p class="text-sm font-semibold text-gray-300">ユーザー追加</p>
              <input id="note" v-model="InviteeEmail" placeholder="追加するユーザーのメールアドレス..."
                class="mt-1 w-full bg-gray-800 text-white border border-gray-600 p-2 rounded-md" />
            </div>
          </div>
        </template>
        <template #footer>
          <button @click="openTokenDailog = false"
            class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="AddNewFreind"
            class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded-md">友達に追加</button>
        </template>
      </Dialog>
    </div>
  </div>
</template>

<script setup>
import Header from '~/components/Header.vue';
import Aside from '~/components/Aside.vue';
// import Main from '~/components/Main.vue';
import '~/assets/css/index.css';
import Dialog from '~/components/MainDialog.vue';
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useAuthFreinds } from '~/store/freind';
import { useAuthLibrary } from '~/store/library';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
const openTokenDailog = ref(false);
const openGroupDailog = ref(false);
const openLibraryDailog = ref(false);
const isSidebarOpen = ref(false);
onMounted(async () => {
  try {
    groupList.value = await groupStore.fetchGroup();
    libraries.value = await libraryStore.FetchLibrary();
    friends.value = await friendStore.fetchFreind();
  } catch (error) {

  }
});
const groupStore = useAuthGroups();
const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const friendStore = useAuthFreinds();
const currentUser = computed(() => authStore.currentUser);

const groupName = ref("");
const groupTag = ref("");
const is_group = ref(false);

const libraryName = ref('');
const libraryTag = ref('');
const is_library = ref(false);

const InviteeEmail = ref('');
const is_invite = ref(false);

const groupList = ref([]);
const libraries = ref([]);
const friends = ref([]);
const targetList = ref([1, 2, 3, 4, 5]);
const router = useRouter();
const toggleSidebar = () => {
  isSidebarOpen.value = true;
};
const close = () => {
  isSidebarOpen.value = false;
};
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
  // const members = [user?.email];
  const visibility = is_group.value;
  if (!GroupName) {
    alert('スタジオ名を入力してください。');
    return;
  }
  try {
    openGroupDailog.value = false;
    const createStudio = await groupStore.CreateGroup(
      GroupName,
      visibility,
      Tag
    );
    console.log('作成結果：', createStudio);
    groupList.value = await groupStore.fetchGroup();
    console.log('Studioが作成されました。');
    openGroupDailog.value = false;
    return router.push(`/studio/${createStudio.id}`);
  } catch (error) {
    console.error('スタジオ作成失敗：', error);
    throw error;
  }
};
const groups = computed(() =>
  groupList.value.filter((item) => item.owner === authStore.user.email)
);
const createLibrary = async () => {
  const user = authStore?.user;
  if (!user) {
    alert('ログインしてください。');
    return;
  }
  const Name = libraryName.value.trim();
  const Tag = libraryTag.value.trim();
  const visibility = is_library.value;
  if (!Name) {
    alert('ライブラリ名を入力してください。');
  }
  try {
    const NewLibrary = await libraryStore.CreateLibraries(
      Name,
      Tag,
      visibility
    );
    console.log('作成結果:', NewLibrary.value);
    libraries.value = await libraryStore.FetchLibrary();
    openLibraryDailog.value = false;
    console.log('ライブラリ作成完了');
    return router.push(`/library/${NewLibrary.id}`);
  } catch (error) {
    console.error('作成失敗：', error);
    throw error;
  }
};
const libraryList = computed(() =>
  libraries.value.filter((item) => item.owner === authStore.user.email)
);
const AddNewFreind = async () => {
  const userId = authStore.user.id;
  const TargetEmail = InviteeEmail.value.trim();

  try {
    const invite = await friendStore.sendFriendRequest(TargetEmail);
    const result = await friendStore.approveFriendInvite(invite.token || invite.id);

    console.log('結果：', result);
    friends.value = await friendStore.fetchFreind();
    openTokenDailog.value = false;
    console.log('友達リクエスト送信済み');
  } catch (err) {
    console.error('リクエスト送信失敗：', err);
    throw err;
  }
};
</script>
