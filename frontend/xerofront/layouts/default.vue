<template>
  <div class="flex flex-col h-screen bg-gray-50 dark:bg-zinc-800 text-gray-800 dark:text-white">
    <header class="sticky top-0 z-50 bg-white dark:bg-zinc-900 shadow">
      <Header @toggle-sidebar="toggleSidebar" v-model:isAsideOpen="asideOpen" v-model:isSabAsideOpen="sabAsideOpen" />
    </header>
    <div class="flex flex-1 overflow-hidden">
      <aside class="hidden md:block">
        <Aside @search-dialog="openSearchDialog" @toggle-sidebar="toggleSidebar" @Token-dialog="TokenDialog()"
          @Library-dialog="LibraryDailog()" @Group-dialog="GroupDailog" :isOpen="isSidebarOpen" 
          @close="isSidebarOpen = false" :isAsideOpen ="asideOpen" :isSabAsideOpen="sabAsideOpen"/>
      </aside>
      <main class="flex-1 overflow-y-auto">
        <NuxtPage @toggle-sidebar="toggleSidebar" @Member-dialog="ShowMember()" @QR-dialog="QRdialog()" @Goal-dialog="CreateGoal()"
          @DockingtoStudio-dialog="DockingLibrary()" @Goalvote-dialog="GoalVoting()" @Vote-dialog="Votedialog(voteId)"
          @Folder-dialog="openFolder(libraryId)" @Library-dialog="LibraryDailog()" @Group-dialog="GroupDailog()"/>
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
          <button @click="Voting()" class="px-2 py-2 rounded bg-yellow-600 hover:bg-green-700 font-medium transition">
            作成する
          </button>
        </template>
      </Dialog>
      <Dialog :visible="openVotedialog" @close="openVotedialog = false">
        <!-- Header -->
        <template #header>
          <div class="flex items-center gap-3">
            <div class="h-9 w-9 rounded-xl bg-emerald-600/10 dark:bg-emerald-400/10 flex items-center justify-center">
              <svg class="h-5 w-5 text-emerald-600 dark:text-emerald-400" viewBox="0 0 24 24" fill="currentColor">
                <path
                  d="M12 2a10 10 0 1 0 10 10A10.011 10.011 0 0 0 12 2m-1 15-5-5 1.41-1.41L11 13.17l6.59-6.58L19 8z" />
              </svg>
            </div>
            <div class="min-w-0">
              <h2 class="text-lg md:text-xl font-bold text-gray-900 dark:text-white truncate">
                {{ selectedVote?.explain || 'この提案に投票' }}
              </h2>
              <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                選択してから「投票する」を押してください（Y=賛成 / N=反対 / Esc=閉じる）
              </p>
            </div>
          </div>
        </template>

        <!-- Body -->
        <template #default>
          <div class="mt-2 space-y-4">
            <!-- 選択カード -->
            <div class="text-xl">
              これは <span
                class="inline-block bg-zinc-100 dark:bg-zinc-700 px-2 py-0.5 rounded text-xs font-medium tracking-wide">#{{
                  selectedVote?.goal?.header }}</span>に関連する投票です
            </div>
            <div></div>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <!-- YES -->
              <button type="button" :aria-pressed="choice === 'yes'" @click="choice = 'yes'" class="group relative w-full rounded-2xl border border-gray-200 dark:border-zinc-700 p-4 text-left
                 hover:border-emerald-400/70 hover:shadow-sm focus:outline-none focus:ring-2 focus:ring-emerald-400
                 data-[active=true]:border-emerald-500 data-[active=true]:ring-1 data-[active=true]:ring-emerald-500"
                :data-active="choice === 'yes'">
                <div class="flex items-center gap-3">
                  <div class="h-10 w-10 rounded-xl bg-emerald-500/10 flex items-center justify-center">
                    <span class="text-2xl">👍</span>
                  </div>
                  <div class="min-w-0">
                    <div class="font-semibold text-gray-900 dark:text-white">賛成</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">提案に同意します</div>
                  </div>
                </div>
                <div v-if="choice === 'yes'" class="absolute right-3 top-3">
                  <span
                    class="inline-flex items-center rounded-lg px-2 py-1 text-xs font-medium bg-emerald-500/10 text-emerald-600">
                    選択中
                  </span>
                </div>
              </button>

              <!-- NO -->
              <button type="button" :aria-pressed="choice === 'no'" @click="choice = 'no'" class="group relative w-full rounded-2xl border border-gray-200 dark:border-zinc-700 p-4 text-left
                 hover:border-rose-400/70 hover:shadow-sm focus:outline-none focus:ring-2 focus:ring-rose-400
                 data-[active=true]:border-rose-500 data-[active=true]:ring-1 data-[active=true]:ring-rose-500"
                :data-active="choice === 'no'">
                <div class="flex items-center gap-3">
                  <div class="h-10 w-10 rounded-xl bg-rose-500/10 flex items-center justify-center">
                    <span class="text-2xl">👎</span>
                  </div>
                  <div class="min-w-0">
                    <div class="font-semibold text-gray-900 dark:text-white">反対</div>
                    <div class="text-xs text-gray-500 dark:text-gray-400">提案に反対します</div>
                  </div>
                </div>
                <div v-if="choice === 'no'" class="absolute right-3 top-3">
                  <span
                    class="inline-flex items-center rounded-lg px-2 py-1 text-xs font-medium bg-rose-500/10 text-rose-600">
                    選択中
                  </span>
                </div>
              </button>
            </div>
          </div>
        </template>

        <!-- Footer -->
        <template #footer>
          <div class="flex w-full items-center justify-between gap-3">
            <button type="button" @click="handleClose" class="px-4 py-2 rounded-xl border border-gray-300 dark:border-zinc-700 text-gray-700 dark:text-gray-200
               hover:bg-gray-100 dark:hover:bg-zinc-800 transition">
              キャンセル（Esc）
            </button>
            <div class="flex items-center gap-2">
              <button v-if="isVoting"
                class="px-5 py-2 rounded-xl bg-indigo-600 text-white font-semibold
                 enabled:hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition flex items-center gap-2"
                type="button" @click="EditVote(selectedVote?.goal?.id)" :disabled="!choice || loading">
                <svg v-if="loading" class="h-5 w-5 animate-spin" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-opacity="0.25" stroke-width="4" />
                  <path d="M22 12a10 10 0 0 1-10 10" stroke="currentColor" stroke-width="4" />
                </svg>
                <span>変更する</span>
              </button>
              <button v-else type="button" @click="doSubmit(selectedVote?.goal?.id)" :disabled="!choice || loading"
                class="px-5 py-2 rounded-xl bg-indigo-600 text-white font-semibold
                 enabled:hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition flex items-center gap-2">
                <svg v-if="loading" class="h-5 w-5 animate-spin" viewBox="0 0 24 24" fill="none">
                  <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-opacity="0.25" stroke-width="4" />
                  <path d="M22 12a10 10 0 0 1-10 10" stroke="currentColor" stroke-width="4" />
                </svg>
                <span>投票する</span>
              </button>
            </div>
          </div>
        </template>
      </Dialog>
      <Dialog :visible="openLibraryfolder" @close="openLibraryfolder = false">
        <template #header>
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="h-10 w-10 rounded-xl bg-indigo-100 dark:bg-indigo-900/40 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-indigo-600 dark:text-indigo-300"
                  viewBox="0 0 24 24" fill="currentColor">
                  <path d="M10 4l2 2h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6c0-1.1.9-2 2-2h6z" />
                </svg>
              </div>
              <div>
                <h2 class="text-lg md:text-xl font-bold text-zinc-900 dark:text-white">{{ selectedLib.name }} フォルダ</h2>
                <p class="text-xs text-zinc-500 dark:text-zinc-400">検索・並び替え・アップロードのみのシンプル版</p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <span
                class="px-2 py-1 text-xs rounded-full bg-zinc-100 dark:bg-zinc-700 text-zinc-700 dark:text-zinc-200">{{
                  files.length }} ファイル</span>
              <button @click="refreshFiles"
                class="px-3 py-1.5 text-xs rounded-lg border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-700">更新</button>
            </div>
          </div>
        </template>

        <!-- Body -->
        <template #default>
          <div class="space-y-4">
            <!-- ツールバー -->
            <div class="flex flex-col md:flex-row gap-3 md:items-center md:justify-between">
              <div class="flex items-center gap-2">
                <div class="relative">
                  <input v-model="query" type="text" placeholder="ファイル検索"
                    class="w-64 rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 pl-9 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500" />
                  <svg class="absolute left-3 top-2.5 h-4 w-4 text-zinc-400" xmlns="http://www.w3.org/2000/svg"
                    viewBox="0 0 24 24" fill="currentColor">
                    <path
                      d="M10 18a8 8 0 1 1 5.292-14.01l4.359 4.36-1.414 1.414-3.94-3.94A6 6 0 1 0 10 16a5.96 5.96 0 0 0 3.87-1.39l1.42 1.42A7.96 7.96 0 0 1 10 18z" />
                  </svg>
                </div>
                <select v-model="sortKey"
                  class="rounded-xl border border-zinc-200 dark:border-zinc-700 bg-white dark:bg-zinc-800 px-3 py-2 text-sm">
                  <option value="updated">更新順</option>
                  <option value="name">名前順</option>
                  <option value="size">サイズ順</option>
                </select>
              </div>
              <div class="flex items-center gap-2">
                <input ref="fileInput" type="file" multiple class="hidden" @change="handlePick" />
                <button type="button" @click="openPicker"
                  class="px-4 py-2 rounded-xl bg-indigo-600 text-white hover:bg-indigo-500">アップロード</button>
              </div>
            </div>

            <!-- 一覧 -->
            <div v-if="filterFiles.length"
              class="divide-y divide-zinc-100 dark:divide-zinc-700 rounded-xl border border-zinc-200 dark:border-zinc-700 h-[44vh] overflow-y-auto overscroll-contain scroll-smooth pr-2">
              <div v-for="f in filterFiles" :key="f.id"
                class="flex items-center justify-between gap-3 px-4 py-3 hover:bg-zinc-50 dark:hover:bg-zinc-800/60">
                <div class="flex items-center gap-3 min-w-0">
                  <div
                    class="h-9 w-9 rounded-lg bg-zinc-100 dark:bg-zinc-700 flex items-center justify-center shrink-0">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zinc-600 dark:text-zinc-300"
                      viewBox="0 0 24 24" fill="currentColor">
                      <path d="M6 2h7l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4c0-1.1.9-2 2-2z" />
                    </svg>
                  </div>
                  <div class="min-w-0">
                    <!-- <p class="truncate font-medium text-zinc-900 dark:text-white">{{ formatFile(f.file) }}</p> -->
                    <p class="truncate font-medium text-zinc-900 dark:text-white">{{ f.name }}</p>
                    <p class="text-xs text-zinc-500 dark:text-zinc-400 truncate">{{ formatSize(f.size) }} ・ {{
                      formatDate(f.created_at || f.updated_at) }}</p>
                  </div>
                </div>
                <button @click="openfile(f)"
                  class="px-2 py-1.5 text-sm rounded-lg border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-700">DL</button>
              </div>
            </div>
            <div v-else class="rounded-2xl border border-dashed border-zinc-300 dark:border-zinc-700 p-10 text-center">
              <p class="text-zinc-600 dark:text-zinc-300 font-medium">このフォルダにはまだファイルがありません</p>
              <p class="text-sm text-zinc-500 dark:text-zinc-400">上の「アップロード」から追加できます</p>
            </div>

            <!-- 進捗 -->
            <div v-if="uploading" class="mt-2">
              <div class="h-2 w-full rounded-full bg-zinc-200 dark:bg-zinc-700 overflow-hidden">
                <div class="h-2 bg-indigo-600 transition-all" :style="{ width: uploadProgress + '%' }"></div>
              </div>
              <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">{{ uploadProgress }}%</p>
            </div>
          </div>
        </template>

        <!-- Footer -->
        <template #footer>
          <div class="flex items-center justify-between w-full">
            <div class="text-xs text-zinc-500 dark:text-zinc-400">最大 100MB / ファイル ・ JPG, PNG, PDF, ZIP</div>
            <!-- <button class="">サブフォルダを作成</button> -->
          </div>
        </template>
      </Dialog>
      <SearchDialog v-model="showSearch" :fetcher="fetchSuggestions" :toLabel="(x) => x.title"
        :toDesc="(x) => x.subtitle" placeholder="ライブラリ・スタジオを検索…" :initialQuery="''"
        @select="(item) => console.log('選択:', item)" />

    </div>
  </div>
</template>
<script setup>
import Header from '~/components/Header.vue';
import Aside from '~/components/Aside.vue';
import '~/assets/css/index.css';
import Dialog from '~/components/MainDialog.vue';
import SearchDialog from '~/components/SearchDialog.vue';
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useGoalStore } from '~/store/goal';
import { useAuthLibrary } from '~/store/library';
import { useAuthVote } from '~/store/vote';
import { ref, onMounted, provide } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { QrcodeCanvas } from 'qrcode.vue';
import { useRuntimeConfig } from '#imports';
import { eventBus } from '#imports';
import { useSearchStore } from '~/store/search';
import {
  hasVote,
  getVote,
  setVote,
  loadVote
} from '~/composables/useVoteHistory.js';

const asideOpen = ref(false);
const sabAsideOpen = ref(false);
const userId = computed(() =>authStore.user?.id);
const openTokenDailog = ref(false);
const openGroupDailog = ref(false);
const showSearch = ref(false);
const search = useSearchStore();
const fetchSuggestions = async (q) => {
  try {
    const token = useAuthStore().accessToken;
    const config = useRuntimeConfig();
    const res = await $fetch(`${config.public.apiBase}search/?q=${encodeURIComponent(q)}`, {
      headers: {
        Authorization: `Bearer ${token}`,
      }
    });
    console.log('結果：', res);
    // 検索結果を整形
    return [
      ...res.groups.map(g => ({ title: g.name, subtitle: 'グループ', data: g })),
      ...res.libraries.map(l => ({ title: l.name, subtitle: 'ライブラリ', data: l })),
    ];
  } catch (e) {
    console.error("検索エラー:", e);
    return [];
  }
}
const authGroup = useAuthGroups();
const authGoal = useGoalStore();
const openLibraryDailog = ref(false);
const isSidebarOpen = ref(false);
const group = ref([]);
const groupStore = useAuthGroups();
const authStore = useAuthStore();
const libraryStore = useAuthLibrary();
const currentUser = computed(() => authStore.currentUser);
const goalHead = ref('');
const goalDescription = ref('');
const goalDeadline = ref('');
const groupName = ref("");
const groupTag = ref("");
const is_group = ref(false);
const openLibraryfolder = ref(false);
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
// const openVotedialog = ref(false);
const selectedVoteId = ref(null);
const selectedLibrary = ref(null);
const allvotes = ref([]);
const voteId = ref('');
const library = ref([]);
const libraryId = ref('');
const my_files = ref([]);
onMounted(async () => {
  try {
    library.value = await libraryStore.FetchDockingLibrary(routeId);
    groupList.value = await groupStore.fetchGroup();
    libraries.value = await libraryStore.FetchLibrary();
    my_libraries.value = await libraryStore.fetchMylibrary();
    group.value = await authGroup.fetchGroupId(routeId);
    goals.value = await authGoal.fetchGoalsByGroup(routeId);
    allvotes.value = await authVote.FetchVotes();
    eventBus.on('Vote-dialog', handleVotedialog);
    eventBus.on('Folder-dialog', openFolder);
    my_files.value = await libraryStore.FetchLibraryFiles();
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
const goHome = () => {
  router.push('/');
};
onBeforeUnmount(() => {
  eventBus.off('Vote-dialog', handleVotedialog);
  eventBus.off('Folder-dialog', openFolder);
});
async function fetchSyggestions(q) {
  const res = await $fetch(`${config.public.apiBase}search/`, {
    query: { q }
  });
  return res.items
}
function onSelect(items) {

}
function onSubmit(query) {

}
const openSearchDialog = () => {
  showSearch.value = true;
};
const selectedVote = computed(() => {
  if (Array.isArray(allvotes.value)) {
    return allvotes.value.find((v) => v.id === selectedVoteId.value);
  }
});
const selectedLib = computed(() => {
  if (Array.isArray(libraries.value)) {
    return libraries.value.find((lib) => lib.id === selectedLibrary.value);
  }
})
const filterFiles = computed(() => {
  return my_files.value.filter((file) => file.target.id === selectedLib.value.id)
})
function openFolder(libraryId) {
  selectedLibrary.value = libraryId;
  openLibraryfolder.value = true;
};
function handleVotedialog(voteId) {
  selectedVoteId.value = voteId;
  openVotedialog.value = true;
};

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
// const handleClose = () =>{
//   openVotedialog.value = false;
// };
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
      closeDockingLibrary();
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
  try {
    if (!goalId) {
      console.error('ゴールIDが選択されていません。');
      return;
    }
    console.log("ゴールのID:", goalId);
    console.log("投票の内容:", vote);
    const response = await authVote.CreateVote(routeId, goalId, vote);
    if (response) {
      console.log('投票の作成成功:', response);
      isVotingdailog.value = false;
      voteValue.value = '';
      selectedGoalId.value = '';
      goals.value = await authGoal.fetchGoalsByGroup(routeId);
      console.log('投票が作成されました。');
      return router.go(0);
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
  console.log('投票:', value);
  if (value === "yes") {
    authVote.PostVoteToGoal(selectedVote.value.goal.id, true);
  } else if (value === 'no') {
    authVote.PostVoteToGoal(selectedVote.value.goal.id, false);
  }
  openVotedialog.value = false;
};
// --- state ---
const files = ref([]);
const uploading = ref(false);
const uploadProgress = ref(0);
const config = useRuntimeConfig();
// <input ref="fileInput" type="file" multiple> に紐づける
const fileInput = ref(null);

// APIルート例: `${config.public.apiBase}library_files/`
const API_BASE = config.public.apiBase;

// 最低限の1件アップロード関数（FormData使用時は Content-Type を自前で付けない）
const uploadFile = async (file) => {
  const fd = new FormData();
  fd.append('file', file);

  // ← サーバ仕様に合わせてキー名を調整
  fd.append('target', String(selectedLib.value.id));
  // fd.append('groupId', String(route.params.id));

  const res = await fetch(`${API_BASE}library_files/`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${authStore.accessToken}`,
    },
    body: fd,
  });

  if (!res.ok) {
    const text = await res.text().catch(() => '');
    throw new Error(`Upload failed (${res.status}): ${text || 'no body'}`);
  }
  return res.json();
};

// 複数ファイルアップロード（順次）＋簡易進捗
const uploadFiles = async (fileList) => {
  uploading.value = true;
  uploadProgress.value = 0;

  const total = fileList.length;
  const uploaded = [];

  try {
    for (let i = 0; i < total; i++) {
      const data = await uploadFile(fileList[i]);
      uploaded.push(data);
      uploadProgress.value = Math.round(((i + 1) / total) * 100);
    }
    files.value.push(...uploaded);
    // 必要ならサーバ最新を取り直す
    // await refreshFiles();
  } finally {
    uploading.value = false;
  }
};

// ドラッグ&ドロップ
const isDragging = ref(false);
const handleDrop = async (e) => {
  e.preventDefault();
  e.stopPropagation();
  isDragging.value = false;

  const dropped = Array.from(e.dataTransfer?.files || []);
  if (!dropped.length) return;

  try {
    await uploadFiles(dropped);
  } catch (err) {
    console.error('ファイルアップロード失敗:', err);
  }
};

// ピッカー起動
const openPicker = () => {
  if (fileInput.value) fileInput.value.click();
};

// input[type=file] の change
const handlePick = async (e) => {
  const target = e.target;
  const picked = Array.from(target.files || []);
  if (!picked.length) return;

  try {
    await uploadFiles(picked);
  } catch (err) {
    console.error('ファイルアップロード失敗:', err);
  } finally {
    // 同じファイルを続けて選んでも change が発火するようにクリア
    if (fileInput.value) fileInput.value.value = '';
  }
};
const query = ref('');
const sortKey = ref('updated'); // 'updated' | 'name' | 'size'
const selectedIds = ref([]); // 選択されたファイルのIDリスト
function formatSize(n) {
  if (!Number.isFinite(n) || n <= 0) return '0 B'
  const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB']
  let i = 0
  let v = n
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024
    i++
  }
  // 10未満かつ単位がB以外のときだけ小数1桁
  const digits = v < 10 && i > 0 ? 1 : 0
  return `${v.toFixed(digits)} ${units[i]}`
}

// 日付表示: 2025/08/11 16:45 など（withTime=falseで日付のみ）
const dtfDate = new Intl.DateTimeFormat('ja-JP', {
  year: 'numeric', month: '2-digit', day: '2-digit'
})
const dtfDateTime = new Intl.DateTimeFormat('ja-JP', {
  year: 'numeric', month: '2-digit', day: '2-digit',
  hour: '2-digit', minute: '2-digit'
})

function formatDate(input, { withTime = true } = {}) {
  const d = new Date(input)
  if (Number.isNaN(d.getTime())) return ''
  return withTime ? dtfDateTime.format(d) : dtfDate.format(d)
}
function formatFile(input) {
  if (input && typeof input === 'string' && input.name) return input.name;
  const s = String(input || '');
  if (!s) return '不明なファイル';
  let last = s;
  try {
    const urls = new URL(s, window.location.origin);
    last = urls.pathname.split('/').pop() || s;
  } catch (e) {
    last = s.split('/').pop() || '';
  }
  last = last.split('?')[0].split('#')[0];
  let decode = last;
  try {
    decode = decodeURIComponent(last);
  } catch (error) {
    decode = last.replace(/%[0-9A-Fa-f]{2}/g, m => {
      try { return decodeURIComponent(m); } catch (e) { return m; }
    });
  }
  return decode.normalize('NFC');
};



const openVotedialog = defineModel('openVotedialog', { required: true }) // v-model:openVotedialog

// 親から渡される props（JS用ランタイム定義）
const props = defineProps({
  selectedVote: {
    type: Object,
    default: () => ({})
  }
})

const choice = ref('')
const note = ref('')
const loading = ref(false)
const error = ref('')
// 送信イベント（JSは配列で定義）
const emit = defineEmits(['submit'])
const isVoting = computed(() => {
  const goalId = props.selectedVote?.goal?.id;
  if (!userId.value || !goalId) return false;
  return hasVote(userId.value, goalId);
});

const handleClose = () => {
  choice.value = ''
  note.value = ''
  error.value = ''
  openVotedialog.value = false
}
const doSubmit = async (routeId) => {
  const selected = choice.value;
  error.value = '';
  if (!selected) {
    error.value = '賛成または反対を選択してください。'
    return
  }
  try {
    loading.value = true
    // 親へ submit イベントを送出（リスナーが async でもOK）
    const res = await fetch(`${config.public.apiBase}goals/${routeId}/vote/`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${authStore.accessToken}`,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        is_yes: selected === 'yes'
      })
    });
    routeId.progress = res.progress
    routeId.is_completed = res.completed
    routeId.myVote = res.vote.is_yes
    const raw = await res.text();
    let data = null;
    try {
      data = raw ? JSON.parse(raw) : null;
    } catch { }
    if (!res.ok) {
      const msg =
        (data && (data.detail || data.error)) ||
        (typeof data === 'string' ? data : '') ||
        raw || `HTTP ${res.status}`;
      error.value = msg;                      // ← 画面に表示
      console.error('vote 400 data:', data || raw);
      return data;
    }
    setVote(userId, routeId, selected);
    console.log(`投票完了:`, data);
    openVotedialog.value = false;
    window.location.reload();
    return data;
  } catch (e) {
    error.value = (e && e.message) || '送信に失敗しました。時間をおいて再度お試しください。'
  } finally {
    loading.value = false
  }
};
const EditVote = async (routeId) => {
  const selected = choice.value;
  error.value = '';
  if (!selected) {
    error.value = '賛成または反対を選択してください。'
    return
  }
  try {
    if (hasVote(userId, routeId)) {
      loading.value = true;
      const res = await fetch(`${config.public.apiBase}goals/${routeId}/vote/`, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${authStore.accessToken}`,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: JSON.stringify({
          is_yes: selected === 'yes'
        }),
      });
      const raw = await res.text(); // ← 本文を必ず吸う
      let data = null;
      try { data = raw ? JSON.parse(raw) : null; } catch { }

      if (!res.ok) {
        const msg =
          (data && (data.detail || data.error)) ||
          (typeof data === 'string' ? data : '') ||
          raw || `HTTP ${res.status}`;
        error.value = msg;                      // ← 画面に表示
        console.error('vote 400 data:', data || raw);
        return;
      }
      console.log(`投票完了:`, data);
      openVotedialog.value = false;
      return data;
    }else{
      doSubmit();
      return;
    }
  } catch (err) {
    error.value = (err && err.message) || '送信に失敗';
  } finally {
    loading.value = false;
  }
};

// キーボードショートカット（Y/N/Esc）
const onKey = (e) => {
  if (!openVotedialog.value) return
  if (e.key === 'y' || e.key === 'Y') {
    choice.value = 'yes'
  } else if (e.key === 'n' || e.key === 'N') {
    choice.value = 'no'
  } else if (e.key === 'Escape') {
    handleClose()
  }
}

onMounted(() => window.addEventListener('keydown', onKey))
onBeforeUnmount(() => window.removeEventListener('keydown', onKey))
const openfile = async (f) => {
  const config = useRuntimeConfig();
  const authStore = useAuthStore();
  try {
    const res = await fetch(`${config.public.apiBase}library_files/${f.id}/download/`, {
      method: "GET",
      headers: {
        "Authorization": `Bearer ${authStore.accessToken}`
      },
    });
    if (!res.ok) {
      const msg = await res.text().catch(() => '');
      throw new Error(`HTTP ${res.status} ${msg}`);
    }
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const previewable = /^(image|video|audio|text|application\/pdf)/i.test(blob.type);
    if (previewable) {
      window.open(url, '_blank');
    } else {
      const a = document.createElement('a');
      a.href = url;
      a.download = (f.file?.split('/')?.pop()) || 'download';
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
    }
  } catch (error) {
    console.error('ファイルを開示で決ま全でした。');
  }
};
</script>