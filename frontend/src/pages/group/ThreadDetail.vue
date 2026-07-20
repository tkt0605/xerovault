<template>
  <div class="flex h-[calc(100vh-57px)] flex-col">
    <div v-if="!rootMessage" class="flex flex-1 items-center justify-center text-ink-faint">
      読み込み中...
    </div>
    <template v-else>
      <!-- ヘッダー -->
      <div class="shrink-0 mx-auto w-full max-w-3xl p-6 pb-4">
        <button
          class="mb-2 flex items-center gap-1 text-xs text-ink-faint transition-colors hover:text-ink"
          @click="router.push(`/group/${route.params.id}?section=posts`)"
        >
          <Icon name="chevron-left" :size="13" />
          スレッド一覧へ
        </button>
        <h1 class="truncate font-serif text-lg font-medium text-ink">
          {{ rootMessage.text }}
        </h1>
        <p class="mt-0.5 text-xs text-ink-faint">
          {{ rootMessage.author.name ?? rootMessage.author.email }}が開始
        </p>
      </div>

      <!-- メッセージ -->
      <div ref="scrollArea" class="flex-1 overflow-y-auto p-4">
        <div class="mx-auto w-full max-w-3xl space-y-3">
          <div
            v-for="msg in groupPostStore.messages"
            :key="msg.id"
            class="flex items-start gap-2"
            :class="isMine(msg) ? 'flex-row-reverse' : ''"
          >
            <Avatar v-if="!isMine(msg)" :name="msg.author.name ?? msg.author.email" :size="32" />
            <div class="min-w-0 max-w-[75%]" :class="isMine(msg) ? 'flex flex-col items-end' : ''">
              <div
                class="mb-0.5 flex items-center gap-2 text-xs"
                :class="isMine(msg) ? 'flex-row-reverse' : ''"
              >
                <span v-if="!isMine(msg)" class="font-semibold text-ink">{{
                  msg.author.name ?? msg.author.email
                }}</span>
                <span class="text-ink-faint">{{ formatRelativeTime(msg.createdAt) }}</span>
              </div>
              <div
                class="whitespace-pre-wrap break-words rounded-surface px-3.5 py-2 text-sm"
                :class="isMine(msg) ? 'bg-accent text-paper-raised' : 'bg-paper-sunken text-ink'"
              >
                {{ msg.text }}
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 入力欄 -->
      <div class="shrink-0 border-t border-line bg-paper-raised p-3">
        <form class="mx-auto flex w-full max-w-3xl gap-2" @submit.prevent="handleSend">
          <textarea
            v-model="newMessage"
            placeholder="メッセージを入力(280文字まで)"
            rows="1"
            maxlength="280"
            class="flex-1 resize-none rounded-control border border-line bg-paper-raised px-4 py-2 text-sm text-ink placeholder:text-ink-faint transition-colors focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent-soft"
          />
          <BaseButton type="submit" :disabled="!newMessage.trim()">
            <Icon name="send" :size="14" />送信
          </BaseButton>
        </form>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { ThreadMessage } from '@xerovault/shared'
import { useAuthStore } from '@/stores/auth'
import { useGroupPostStore } from '@/stores/groupPost'
import { formatRelativeTime } from '@/lib/activity'
import { useThreadEvents } from '@/composables/useThreadEvents'
import Avatar from '@/components/ui/Avatar.vue'
import Icon from '@/components/ui/Icon.vue'
import BaseButton from '@/components/ui/BaseButton.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const groupPostStore = useGroupPostStore()

const newMessage = ref('')
const scrollArea = ref<HTMLElement | null>(null)

const rootMessage = computed(() => groupPostStore.messages[0] ?? null)

function isMine(msg: ThreadMessage): boolean {
  return msg.authorId === authStore.user?.id
}

// URLのthreadIdはスレッド内の任意のメッセージid(ルートでも返信でも良い)。
// get_thread_messagesが内部でルートへ解決するため、リアルタイム購読や
// 送信先には、取得結果から分かる実際のルートid(rootMessage.id)を使う。
const requestedId = route.params.threadId as string

onMounted(async () => {
  await groupPostStore.fetchMessages(requestedId)
  if (rootMessage.value) {
    useThreadEvents(rootMessage.value.id, () => groupPostStore.fetchMessages(rootMessage.value!.id))
  }
  await nextTick()
  scrollToBottom()
})

watch(
  () => groupPostStore.messages.length,
  () => nextTick(scrollToBottom)
)

function scrollToBottom() {
  if (scrollArea.value) scrollArea.value.scrollTop = scrollArea.value.scrollHeight
}

async function handleSend() {
  const text = newMessage.value.trim()
  if (!text || !rootMessage.value) return
  newMessage.value = ''
  await groupPostStore.sendMessage(route.params.id as string, rootMessage.value.id, text)
}
</script>
