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
          @DockingtoStudio-dialog="DockingLibrary()" @Goalvote-dialog="GoalVoting()" @Vote-dialog="Votedialog(voteId)"
          @Folder-dialog="openFolder(libraryId)" />
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
          <h2 class="text-xl font-bold text-gray-800 dark:text-white">{{ selectedVote?.explain }}</h2>
        </template>
        <template #default>
          <!-- ここに投票のyesかNoを選択するUIを作成。 -->
          <div class="mt-4 flex justify-center gap-6">
            <button @click="submitVote('yes')"
              class="px-6 py-3 bg-green-500 text-white font-semibold rounded-xl hover:bg-green-600 transition">
              👍 賛成😁
            </button>
            <button @click="submitVote('no')"
              class="px-6 py-3 bg-red-500 text-white font-semibold rounded-xl hover:bg-red-600 transition">
              👎 反対😒
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
      <Dialog :visible="openLibraryfolder" @close="openLibraryfolder = false">
        <!-- Header -->
        <template #header>
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <div class="h-10 w-10 rounded-xl bg-indigo-100 dark:bg-indigo-900/40 flex items-center justify-center">
                <!-- フォルダアイコン -->
                <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-indigo-600 dark:text-indigo-300"
                  viewBox="0 0 24 24" fill="currentColor">
                  <path d="M10 4l2 2h8a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V6c0-1.1.9-2 2-2h6z" />
                </svg>
              </div>
              <div>
                <h2 class="text-lg md:text-xl font-bold text-zinc-900 dark:text-white">
                  {{ selectedLib?.name }} フォルダ
                </h2>
                <p class="text-xs text-zinc-500 dark:text-zinc-400">
                  追加・並び替え・共有をここから操作
                </p>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <span
                class="px-2 py-1 text-xs rounded-full bg-zinc-100 dark:bg-zinc-700 text-zinc-700 dark:text-zinc-200">
                {{ files.length }} ファイル
              </span>
              <button @click="refreshFiles"
                class="px-3 py-1.5 text-xs rounded-lg border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-50 dark:hover:bg-zinc-700">
                更新
              </button>
            </div>
          </div>
        </template>
        <template #default>
          <div class="space-y-4">
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
                <button @click="selectAll"
                  class="text-sm px-3 py-2 rounded-lg hover:bg-zinc-100 dark:hover:bg-zinc-700">
                  全選択
                </button>
                <button @click="deleteSelected" :disabled="!selectedIds.length"
                  class="text-sm px-3 py-2 rounded-lg bg-rose-600 text-white disabled:opacity-40 hover:bg-rose-500">
                  削除
                </button>
              </div>
            </div>
            <div v-if="filteredFiles.length"
              class="divide-y divide-zinc-100 dark:divide-zinc-700 rounded-xl border border-zinc-200 dark:border-zinc-700 overflow-hidden">
              <div v-for="f in filteredFiles" :key="f.id"
                class="flex items-center justify-between gap-3 px-4 py-3 hover:bg-zinc-50 dark:hover:bg-zinc-800/60">
                <div class="flex items-center gap-3 min-w-0">
                  <input type="checkbox" v-model="selectedIds" :value="f.id"
                    class="rounded border-zinc-300 text-indigo-600 focus:ring-indigo-500">
                  <div
                    class="h-9 w-9 rounded-lg bg-zinc-100 dark:bg-zinc-700 flex items-center justify-center shrink-0">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-zinc-600 dark:text-zinc-300"
                      viewBox="0 0 24 24" fill="currentColor">
                      <path d="M6 2h7l5 5v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V4c0-1.1.9-2 2-2z" />
                    </svg>
                  </div>
                  <div class="min-w-0">
                    <p class="truncate font-medium text-zinc-900 dark:text-white">{{ f.name }}</p>
                    <p class="text-xs text-zinc-500 dark:text-zinc-400 truncate">
                      {{ formatSize(f.size) }} ・ {{ formatDate(f.updated_at) }}
                    </p>
                  </div>
                </div>
                <div class="flex items-center gap-2">
                  <button @click="downloadFile(f)"
                    class="px-2 py-1.5 text-sm rounded-lg border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover:bg-zinc-700">DL</button>
                  <button @click="renameFile(f)"
                    class="px-2 py-1.5 text-sm rounded-lg border border-zinc-200 dark:border-zinc-700 hover:bg-zinc-100 dark:hover	bg-zinc-700">名称変更</button>
                  <button @click="deleteOne(f)"
                    class="px-2 py-1.5 text-sm rounded-lg bg-rose-600 text-white hover:bg-rose-500">削除</button>
                </div>
              </div>
            </div>
            <div v-else class="rounded-2xl border border-dashed border-zinc-300 dark:border-zinc-700 p-10 text-center">
              <p class="text-zinc-600 dark:text-zinc-300 font-medium">このフォルダにはまだファイルがありません</p>
              <p class="text-sm text-zinc-500 dark:text-zinc-400">下のアップロードから追加できます</p>
              <div class="text-xs text-zinc-500 dark:text-zinc-400">
                最大 100MB / ファイル ・ JPG, PNG, PDF, ZIP 対応
              </div>
            </div>
            <div @dragover.prevent @drop.prevent="handleDrop"
              class="rounded-2xl border-2 border-dashed border-zinc-300 dark:border-zinc-700 p-6 text-center hover:bg-zinc-50/60 dark:hover:bg-zinc-800/50 transition">
              <p class="text-sm text-zinc-600 dark:text-zinc-300">ここにファイルをドラッグ & ドロップ</p>
              <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">または</p>
              <button @click="$refs.fileInput.click()"
                class="mt-3 px-4 py-2 rounded-xl bg-indigo-600 text-white hover:bg-indigo-500">
                ファイルを選択
              </button>
              <input ref="fileInput" type="file" multiple class="hidden" @change="handlePick">
              <div v-if="uploading" class="mt-4">
                <div class="h-2 w-full rounded-full bg-zinc-200 dark:bg-zinc-700 overflow-hidden">
                  <div class="h-2 bg-indigo-600 transition-all" :style="{ width: uploadProgress + '%' }"></div>
                </div>
                <p class="text-xs text-zinc-500 dark:text-zinc-400 mt-1">{{ uploadProgress }}%</p>
              </div>
            </div>
          </div>
        </template>

        <!-- Footer -->
        <template #footer>
          <div class="flex items-center justify-between w-full">
            <div class="flex items-center justify-end gap-2">
              <button @click="$refs.fileInput.click()"
                class="px-4 py-2 rounded-xl bg-indigo-600 text-white hover:bg-indigo-500">
                アップロードする
              </button>
              <button @click="createSubfolder"
                class="px-3 py-2 rounded-lg bg-zinc-900 text-white dark:bg-white dark:text-zinc-900 hover:opacity-90">
                サブフォルダ作成
              </button>
            </div>
          </div>
        </template>
      </Dialog>

    </div>
  </div>
</template>
<script setup>
import Header from '~/components/Header.vue';
import Aside from '~/components/Aside.vue';
import '~/assets/css/index.css';
import Dialog from '~/components/MainDialog.vue';
import { useAuthStore } from '~/store/auth';
import { useAuthGroups } from '~/store/group';
import { useGoalStore } from '~/store/goal';
import { useAuthLibrary } from '~/store/library';
import { useAuthVote } from '~/store/vote';
import { ref, onMounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { QrcodeCanvas } from 'qrcode.vue';
import { eventBus } from '#imports';
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
const openVotedialog = ref(false);
const selectedVoteId = ref(null);
const selectedLibrary = ref(null);
const allvotes = ref([]);
const voteId = ref('');
const library = ref([]);
const libraryId = ref('');
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
onBeforeUnmount(() => {
  eventBus.off('Vote-dialog', handleVotedialog);
  eventBus.off('Folder-dialog', openFolder);
});
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
const query = ref('')
const sortKey = ref('updated') // "updated" | "name" | "size"
const selectedIds = ref([])
const files = ref([]) // 例: [{ id, name, size, updated_at }, ...]

const uploading = ref(false)
const uploadProgress = ref(0)

const filteredFiles = computed(() => {
  const q = query.value.trim().toLowerCase()
  const arr = files.value.filter(f => (f.name || '').toLowerCase().includes(q))

  const byName = (a, b) => (a.name || '').localeCompare(b.name || '')
  const bySize = (a, b) => (a.size || 0) - (b.size || 0)
  const byUpdated = (a, b) => new Date(b.updated_at || 0) - new Date(a.updated_at || 0)

  const sorters = { name: byName, size: bySize, updated: byUpdated }
  return arr.slice().sort(sorters[sortKey.value] || byUpdated) // sliceで元配列を汚さない
})

function formatSize(n) {
  if (n === undefined || n === null) return '-'
  const units = ['B', 'KB', 'MB', 'GB']
  let i = 0
  let v = Number(n) || 0
  while (v >= 1024 && i < units.length - 1) { v /= 1024; i++ }
  return `${v.toFixed(1)} ${units[i]}`
}

function formatDate(s) {
  const d = new Date(s || 0)
  return isNaN(d.getTime()) ? '-' : d.toLocaleString()
}

function refreshFiles() { /* API で files を再取得して files.value = 結果 */ }
function selectAll() { selectedIds.value = filteredFiles.value.map(f => f.id) }
function deleteSelected() { /* 選択削除 */ }
function deleteOne(f) { /* 単体削除 */ }
function shareSelected() { /* 共有リンク生成 */ }
function renameFile(f) { /* モーダルでリネーム */ }

function handlePick(e) { uploadFiles(e.target.files) }
function handleDrop(e) { uploadFiles(e.dataTransfer && e.dataTransfer.files) }

async function uploadFiles(list) {
  if (!list || !list.length) return
  uploading.value = true
  uploadProgress.value = 0
  // TODO: FormData でアップロード（進捗はXHRで更新 or 擬似カウント）
  // 完了後に再取得
  // await refreshFiles()
  uploading.value = false
  uploadProgress.value = 100
}

function createSubfolder() { /* APIでフォルダ作成 → refreshFiles() */ }
</script>