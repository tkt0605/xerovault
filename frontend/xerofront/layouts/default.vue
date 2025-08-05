<template>
  <div class="flex flex-col h-screen bg-gray-50 dark:bg-zinc-800 text-gray-800 dark:text-white">
    <header class="sticky top-0 z-50 bg-white dark:bg-zinc-900 shadow">
      <Header @toggle-sidebar="toggleSidebar" />
    </header>
    <div class="flex flex-1 overflow-hidden">
      <aside class="hidden md:block">
        <Aside @toggle-sidebar="toggleSidebar" @Token-dialog="TokenDialog()" @Library-dialog="LibraryDailog()"
          @Group-dialog="GroupDailog" :isOpen="isSidebarOpen" @close="isSidebarOpen = false" />
      </aside>
      <main class="flex-1 overflow-y-auto">
        <NuxtPage @Member-dialog="ShowMember()" @QR-dialog="QRdialog()" @Goal-dialog="CreateGoal()"
          @DockingtoStudio-dialog="DockingLibrary()" @Goalvote-dialog="GoalVoting()" @Vote-dialog="Votedialog(voteId)" />
      </main>

      <!-- Dialog コンポーネントは省略 -->
      <!-- 全てのダイアログ部分（openGroupDailog〜isShowMember）をそっくりそのまま展開してください -->
      <Dialog :visible="openGroupDailog" @close="openGroupDailog = false">
        <template #header>
          <h2 class="text-xl font-bold text-gray-800 dark:text-white">スタジオ新規作成</h2>
        </template>
        <template #default>
          <div class="space-y-4">
            <div>
              <input id="group-name" type="text" placeholder="スタジオ名を入力" v-model="groupName"
                class="mt-1 block w-full rounded-md p-2 border bg-white text-black dark:bg-zinc-800 dark:text-white border-gray-300 dark:border-zinc-600" />
            </div>
            <div>
              <label for="lib-tags"
                class="block text-sm font-semibold text-gray-700 dark:text-gray-200">タグ（カンマ区切り）</label>
              <input id="lib-tags" type="text" placeholder="例：機密, AI, レポート" v-model="groupTag"
                class="mt-1 block w-full p-2 rounded-md border bg-white text-black dark:bg-zinc-800 dark:text-white border-gray-300 dark:border-zinc-600" />
            </div>
            <div>
              <span class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">公開設定</span>
              <div class="flex items-center gap-6">
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-green-500" v-model="is_group"
                    :value="true" />
                  <span class="ml-2 text-gray-700 dark:text-gray-200">公開</span>
                </label>
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-red-500" v-model="is_group"
                    :value="false" />
                  <span class="ml-2 text-gray-700 dark:text-gray-200">非公開</span>
                </label>
              </div>
            </div>
          </div>
        </template>
        <template #footer>
          <button @click="openGroupDailog = false"
            class="px-4 py-2 bg-gray-300 text-black dark:bg-gray-600 dark:text-white rounded hover:bg-gray-400 dark:hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="createNewGroup()"
            class="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 transition">
            作成する
          </button>
        </template>
      </Dialog>
      <Dialog :visible="openLibraryDailog" @close="openLibraryDailog = false">
        <template #header>
          <h2 class="text-xl font-bold text-gray-800 dark:text-white">ライブラリ新規作成</h2>
        </template>
        <template #default>
          <div class="space-y-5">
            <div>
              <label for="lib-name" class="block text-sm font-semibold text-gray-700 dark:text-gray-200">ライブラリ名 <span
                  class="text-red-500">*</span></label>
              <input id="lib-name" type="text" placeholder="例：研究資料2025" v-model="libraryName"
                class="mt-1 block w-full p-2 rounded-md border bg-white text-black dark:bg-zinc-800 dark:text-white border-gray-300 dark:border-zinc-600" />
            </div>
            <div>
              <label for="lib-tags"
                class="block text-sm font-semibold text-gray-700 dark:text-gray-200">タグ（カンマ区切り）</label>
              <input id="lib-tags" type="text" v-model="libraryTag" placeholder="例：機密, AI, レポート"
                class="mt-1 block w-full p-2 rounded-md border bg-white text-black dark:bg-zinc-800 dark:text-white border-gray-300 dark:border-zinc-600" />
            </div>
            <div>
              <span class="block text-sm font-medium text-gray-700 dark:text-gray-200 mb-1">公開設定</span>
              <div class="flex items-center gap-6">
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-green-500" v-model="is_library"
                    :value="true" />
                  <span class="ml-2 text-gray-700 dark:text-gray-200">公開</span>
                </label>
                <label class="inline-flex items-center">
                  <input type="radio" name="visibility" class="form-radio text-red-500" v-model="is_library"
                    :value="false" />
                  <span class="ml-2 text-gray-700 dark:text-gray-200">非公開</span>
                </label>
              </div>
            </div>
          </div>
        </template>
        <template #footer>
          <button @click="openLibraryDailog = false"
            class="px-4 py-2 bg-gray-300 text-black dark:bg-gray-600 dark:text-white rounded hover:bg-gray-400 dark:hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="createLibrary"
            class="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 transition">
            作成する
          </button>
        </template>
      </Dialog>
      <Dialog :visible="openGoalDialog" @close="openGoalDialog = false">
        <template #header>
          <h2 class="text-xl font-bold text-gray-800 dark:text-white">🎯 ゴールの作成</h2>
        </template>
        <template #default>
          <div class="space-y-6 py-2">
            <div>
              <label class="block text-sm font-semibold text-gray-700 dark:text-gray-100 mb-1">ゴール名</label>
              <input v-model="goalHead" type="text" placeholder="例：週に1回プロトタイプを提出"
                class="w-full bg-white dark:bg-zinc-800 text-black dark:text-white border border-gray-300 dark:border-zinc-600 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label class="block text-sm font-semibold text-gray-700 dark:text-gray-100 mb-1">詳細な説明</label>
              <textarea v-model="goalDescription" rows="4" placeholder="このゴールの目的や背景、達成のためのアプローチなどを書いてください。"
                class="w-full bg-white dark:bg-zinc-800 text-black dark:text-white border border-gray-300 dark:border-zinc-600 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 resize-y"></textarea>
            </div>
            <div>
              <label class="block text-sm font-semibold text-gray-700 dark:text-gray-100 mb-1">締め切り日（任意）</label>
              <input v-model="goalDeadline" type="date" :min="new Date().toISOString().split('T')[0]"
                class="w-full bg-white dark:bg-zinc-800 text-black dark:text-white border border-gray-300 dark:border-zinc-600 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
          </div>
        </template>
        <template #footer>
          <div class="flex justify-end gap-3 mt-4">
            <button @click="openGoalDialog = false"
              class="px-4 py-2 bg-gray-300 text-black dark:bg-gray-600 dark:text-white rounded hover:bg-gray-400 dark:hover:bg-gray-700 transition">
              キャンセル
            </button>
            <button @click="submitGoal()" class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition">
              作成する
            </button>
          </div>
        </template>
      </Dialog>
      <Dialog :visible="openQRdailog" @close="openQRdailog = false">
        <template #header>
          <h2 class="text-lg font-semibold text-gray-800 dark:text-white">
            {{ group.name }} のQRコード
          </h2>
        </template>
        <template #default>
          <div class="space-y-6">
            <div class="flex justify-center">
              <div class="bg-white dark:bg-zinc-700 p-4 rounded-lg shadow aspect-square">
                <QrcodeCanvas :value="invterURL" :size="180" level="M" />
              </div>
            </div>
            <div class="bg-zinc-100 dark:bg-zinc-800 rounded-lg p-4 space-y-3">
              <div
                class="flex items-center justify-between gap-2 bg-zinc-100 dark:bg-zinc-700 p-3 rounded-lg shadow-inner">
                <input type="text" :value="invterURL" readonly
                  class="w-full px-3 py-2 text-sm rounded-md text-gray-800 dark:text-white bg-white dark:bg-zinc-800 border border-gray-300 dark:border-zinc-600 focus:outline-none" />
                <button @click="copyToClipboard(invterURL)"
                  class="px-3 py-1 text-sm text-white bg-blue-600 hover:bg-blue-700 rounded-md transition">
                  コピー
                </button>
              </div>
              <p class="text-sm text-gray-500 dark:text-gray-400">このコードをコピーして共有してください。</p>
              <div class="flex items-center justify-between gap-2 bg-zinc-100 dark:bg-zinc-600 p-3 rounded shadow">
                <div class="text-sm font-mono text-black dark:text-white break-all">
                  {{ group.joined_token }}
                </div>
                <button @click="copyToClipboard" class="p-2 rounded bg-zinc-600 hover:bg-zinc-700 text-white transition"
                  title="コピー">
                  <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="currentColor" viewBox="0 0 16 16">
                    <path fill-rule="evenodd"
                      d="M4 2a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2zm2-1a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V2a1 1 0 0 0-1-1zM2 5a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1v-1h1v1a2 2 0 0 1-2 2H2a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h1v1z" />
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </template>
        <template #footer>
          <button @click="closeQRdialog"
            class="px-4 py-2 bg-gray-300 text-black dark:bg-gray-600 dark:text-white rounded hover:bg-gray-400 dark:hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="RemoveQR()" class="text-red-600 hover:text-red-700 font-medium transition">
            QRを削除する。
          </button>
        </template>
      </Dialog>
      <Dialog :visible="isShowMember" @close="isShowMember = false">
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold dark:text-white tracking-wide">メンバー</h2>
          </div>
        </template>
        <template #default>
          <div v-for="member in group.members" :key="member.id"
            class="flex items-center justify-between p-4 rounded-lg dark:bg-zinc-800 border border-zinc-700 shadow hover:bg-gray-100 dark:hover:bg-zinc-700 transition">
            <div class="flex items-center space-x-4">
              <img :src="member.avater" class="w-12 h-12 rounded-full border-2 dark:border-white object-cover shadow"
                alt="Member" />
              <div>
                <p class="dark:text-white text-sm font-medium break-all">
                  {{ member.username || member.email || '不明なユーザー' }}
                </p>
                <p class="inline-block mt-2 text-xs text-white bg-green-700 px-2 py-0.5 rounded-full">
                  メンバー
                </p>
              </div>
            </div>
            <button @click="isDeleteAlart(member.id)" class="text-red-500 hover:text-red-400 transition"
              title="このメンバーを削除">
              <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="currentColor" class="bi bi-trash"
                viewBox="0 0 16 16">
                <path d="M5.5 5.5A.5.5 0 0 1 6 5h4a.5.5 0 0 1 .5.5v7a.5.5 0 0 1-1 0V6H6v6.5a.5.5 0 0 1-1 0v-7z" />
                <path fill-rule="evenodd"
                  d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1 0-2H5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1h2.5a1 1 0 0 1 1 1z" />
              </svg>
            </button>
          </div>
        </template>
      </Dialog>
      <Dialog :visible="isDockingdailog" @close="isDockingdailog = false">
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold dark:text-white tracking-wide">ライブラリをドッキングする</h2>
          </div>
        </template>
        <template #default>
          <div class="space-y-4">
            <div>
              <label class="text-sm font-semibold dark:text-white">ドッキング先ライブラリ</label>
              <select v-model="selectedLibraryId"
                class="w-full px-3 py-2 mt-1 bg-white dark:bg-zinc-800 border dark:border-zinc-600 rounded">
                <option v-for="lib in my_libraries" :value="lib.id" :key="lib.id">
                  {{ lib.name }}
                </option>
              </select>
            </div>
          </div>
        </template>
        <template #footer>
          <button @click="closeDockingLibrary()"
            class="px-4 py-2 bg-gray-300 text-black dark:bg-gray-600 dark:text-white rounded hover:bg-gray-400 dark:hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="Docking()" class="px-2 py-2 rounded bg-green-600 hover:bg-green-700 font-medium transition">
            ドッキングする
          </button>
        </template>
      </Dialog>
      <Dialog :visible="isVotingdailog" @close="isVotingdailog = false">
        <template #header>
          <div class="flex items-center justify-between">
            <h2 class="text-xl font-bold dark:text-white tracking-wide">ゴールの投票をする</h2>
          </div>
        </template>
        <template #default>
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-semibold text-gray-700 dark:text-gray-100 mb-1">投票のValue</label>
              <input v-model="voteValue" type="text" placeholder="例：投票の内容を入力"
                class="w-full bg-white dark:bg-zinc-800 text-black dark:text-white border border-gray-300 dark:border-zinc-600 px-4 py-2 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500" />
            </div>
            <div>
              <label class="text-sm font-semibold dark:text-white">対象ゴール</label>
              <select v-model="selectedGoalId"
                class="w-full px-3 py-2 mt-1 bg-white dark:bg-zinc-800 border dark:border-zinc-600 rounded">
                <option v-for="goal in goals" :value="goal.id" :key="goal.id">
                  {{ goal.header }}
                </option>
              </select>
            </div>
          </div>
        </template>
        <template #footer>
          <button @click="closeVoting()"
            class="px-4 py-2 bg-gray-300 text-black dark:bg-gray-600 dark:text-white rounded hover:bg-gray-400 dark:hover:bg-gray-700 transition">
            キャンセル
          </button>
          <button @click="Voting()" class="px-2 py-2 rounded bg-green-600 hover:bg-green-700 font-medium transition">
            作成する
          </button>
        </template>
      </Dialog>
      <Dialog :visible="openVotedialog" @close="openVotedialog = false">
        <template #header>
          <h2 class="text-xl font-bold text-gray-800 dark:text-white">{{ voteValue }}</h2>
        </template>
        <template #default>
          <!-- ここに投票のyesかNoを選択するUIを作成。 -->
          <div class="mt-4 flex justify-center gap-6">
            <button @click="submitVote('yes')"
              class="px-6 py-3 bg-green-500 text-white font-semibold rounded-xl hover:bg-green-600 transition">
              👍 はい
            </button>
            <button @click="submitVote('no')"
              class="px-6 py-3 bg-red-500 text-white font-semibold rounded-xl hover:bg-red-600 transition">
              👎 いいえ
            </button>
          </div>
        </template>
        <template #footer>
          <button @click="openVotedialog = false"
            class="px-4 py-2 bg-gray-300 text-black dark:bg-gray-600 dark:text-white rounded hover:bg-gray-400 dark:hover:bg-gray-700 transition">
            キャンセル
          </button>
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
import { useGoalStore } from '~/store/goal';
import { useAuthLibrary } from '~/store/library';
import { useAuthVote } from '~/store/vote';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { QrcodeCanvas } from 'qrcode.vue';
const openTokenDailog = ref(false);
const openGroupDailog = ref(false);
const authGroup = useAuthGroups();
const authGoal = useGoalStore();
const openLibraryDailog = ref(false);
const isSidebarOpen = ref(false);
const group = ref([]);
const groupStore = useAuthGroups();
const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const friendStore = useAuthFreinds();
const currentUser = computed(() => authStore.currentUser);
const goalHead = ref('');
const goalDescription = ref('');
const goalDeadline = ref('');
const groupName = ref("");
const groupTag = ref("");
const is_group = ref(false);

const libraryName = ref('');
const libraryTag = ref('');
const is_library = ref(false);
const voteValue = ref('');
const InviteeEmail = ref('');
const is_invite = ref(false);
const authVote = useAuthVote();
const groupList = ref([]);
const libraries = ref([]);
const friends = ref([]);
const targetList = ref([1, 2, 3, 4, 5]);
const router = useRouter();
const route = useRoute();
const isShowMember = ref(false);
const openGoalDialog = ref(false);
const openQRdailog = ref(false);
const isDockingdailog = ref(false);
const invterURL = ref('');
const routeId = route.params.id;
const goals = ref([]);
const my_libraries = ref([]);
const isJoinToStudioUrl = ref(false);
const selectedLibraryId = ref('');
const selectedGoalId = ref('');
const my_goals = ref([]);
const isVotingdailog = ref(false);
const openVotedialog = ref(false);
onMounted(async () => {
  try {
    groupList.value = await groupStore.fetchGroup();
    libraries.value = await libraryStore.FetchLibrary();
    my_libraries.value = await libraryStore.fetchMylibrary();
    friends.value = await friendStore.fetchFreind();
    group.value = await authGroup.fetchGroupId(routeId);
    goals.value = await authGoal.fetchGoalsByGroup(routeId);
    // my_goals.value = await authGoal.MyGoals();
    const key = `${group.name}_${route.params.id}`;
    const storedUrl = localStorage.getItem(key);
    if (storedUrl) {
      invterURL.value = storedUrl;
      isJoinToStudioUrl.value = true;
    }
  } catch (error) {
    console.error('エラー:', error);
    throw error;

  }
});

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
const ShowMember = () => {
  isShowMember.value = true;
};
const DockingLibrary = () => {
  isDockingdailog.value = true;
};
const closeDockingLibrary = () => {
  isDockingdailog.value = false;
};
const GoalVoting = () => {
  isVotingdailog.value = true;
}
const closeVoting = () => {
  isVotingdailog.value = false;
};
const QRdialog = () => {
  openQRdailog.value = true;
};
const closeQRdialog = () => {
  openQRdailog.value = false;
};
const CreateGoal = () => {
  openGoalDialog.value = true;
};
const Votedialog = () => {
  openVotedialog.value = true;
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
  group.value.filter((item) => item.owner === authStore.user.email)
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

const copyToClipboard = async () => {
  try {
    await navigator.clipboard.writeText(invterURL.value);
    alert("コピーしました！");
  } catch (err) {
    console.error("コピーに失敗:", err);
    alert("コピーに失敗しました。");
  }
};
const MemberCounter = computed(() => {
  return group.value.members ? group.value.members.length : 0;
});
const submitGoal = async () => {
  const group = route.params.id;
  if (!group) {
    console.error('グループがしてされていません。');
    return;
  }
  const goal_header = goalHead.value.trim();
  const goal_description = goalDescription.value.trim();
  const goal_deadline = goalDeadline.value;
  try {

    if (!goal_header || !goal_description || !goal_deadline) {
      console.error('ゴールの情報が不完全です。');
      return;
    }
    const newGoal = await authGoal.CreateGoal(group, goal_header, goal_description, goal_deadline);
    goals.value = await authGoal.fetchGoals();
    if (goals.value) {
      console.log('新しいゴールが作成されました:', newGoal);
      console.log('目標の作成に成功しました。');
      openGoalDialog.value = false;
      goalHead.value = '';
      goalDescription.value = '';
      goalDeadline.value = '';
    } else {
      console.error('目標の作成に失敗しました。')
    }
  } catch (err) {
    console.error('目標の作成中にエラーが発生しました:', err);
    throw err;
  }
};
const isDeleteAlart = (memberId) => {
  if (currentUser.email === group.owner?.email) {
    if (confirm(`本当にメンバー「${memberId}」を削除しますか？`)) {
      removeMember(memberId);
      RemoveQR();
      console.log('メンバーの削除が完了 | 招待トークンも削除されました。');
    } else {
      console.log('メンバーの削除がキャンセルされました。');
    }
  } else {
    alert('あなたはこのスタジオのオーナーではありません。メンバーを削除する権限がありません。');
  }
};
const removeMember = async (memberId) => {
  const groupId = route.params.id;
  console.log("メンバーID：", memberId);
  try {
    const response = await authGroup.DeleteMember(groupId, memberId);
    if (response) {
      console.log('メンバーの削除完了:', response);
      // メンバー削除後の更新処理
      group.value = await authGroup.fetchGroupId(groupId);
      goals.value = await authGoal.fetchGoalsByGroup(groupId);
      return route.push(`/studio/${groupId}`);
    } else {
      console.error('メンバーの削除に失敗しました。');
      throw new Error('メンバーの削除・失敗:');
    }
  } catch (error) {
    console.error('メンバーの削除中にエラー発生:', error);
    throw error;
  }
};
const RemoveQR = async () => {
  const routeId = route.params.id;
  const key = `${group.name}_${routeId}`;
  const inviteTokens = localStorage.getItem(key);
  if (inviteTokens) {
    localStorage.removeItem(key);
    isJoinToStudioUrl.value = false;
    openQRdailog.value = false
    console.log('削除成功');
  } else {
    console.warn('削除失敗');
  }
};
const Docking = async () => {
  const routeId = route.params.id;
  const targetLibrary = selectedLibraryId.value;
  const user = authStore.user.email;
  if (!user) {
    alert('ログインしてください。');
    return;
  }
  try {
    console.log('ドッキング先ライブラリID:', targetLibrary);
    console.log('ドッキング元スタジオID:', routeId);
    const response = await libraryStore.DockingLibrary(routeId, targetLibrary);
    if (response) {
      console.log('成功:', response);
      group.value = await authGroup.fetchGroupId(routeId);
      goals.value = await authGoal.fetchGoalsByGroup(routeId);
      return router.push(`/studio/${routeId}`);
    }
  } catch (err) {
    console.error('docking失敗：', err);
    throw err;
  }
};
const Voting = async () => {
  const goalId = selectedGoalId.value;
  const routeId = route.params.id;
  const vote = voteValue.value.trim();
  const is_yes = ref(false);
  try {
    if (!goalId) {
      console.error('ゴールIDが選択されていません。');
      return;
    }
    console.log("ゴールのID:", goalId);
    console.log("投票の内容:", vote);
    console.log("投票の選択:", is_yes.value);
    const response = await authVote.CreateVote(routeId, goalId, vote, is_yes.value);
    if (response) {
      console.log('投票の作成成功:', response);
      isVotingdailog.value = false;
      voteValue.value = '';
      selectedGoalId.value = '';
      goals.value = await authGoal.fetchGoalsByGroup(routeId);
      console.log('投票が作成されました。');
    } else {
      console.error('投票の作成に失敗しました。');
      throw new Error('投票の作成・失敗:');
    }
  } catch (err) {
    console.error('投票の作成中にエラーが発生しました', err);
    throw err;
  }
};
const submitVote = (value) => {
  console.log('投票:', value)
  openVotedialog.value = false
}

</script>