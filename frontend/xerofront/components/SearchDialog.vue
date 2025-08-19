<template>
  <teleport to="body">
    <transition name="fade">
      <div v-if="modelValue" class="fixed inset-0 bg-black/50 backdrop-blur-sm z-[100]" @click.self="close" />
    </transition>

    <transition name="pop">
      <div
        v-if="modelValue"
        class="fixed inset-0 z-[101] flex items-start justify-center p-4 md:pt-20"
        role="dialog"
        aria-modal="true"
        :aria-labelledby="titleId"
        @keydown.esc.prevent="close"
        @keydown.down.prevent="move(1)"
        @keydown.up.prevent="move(-1)"
        @keydown.enter.prevent="enter"
      >
        <div class="w-full max-w-2xl rounded-2xl bg-white dark:bg-zinc-900 shadow-2xl overflow-hidden ring-1 ring-black/10 dark:ring-white/10">
          <!-- Header -->
          <div class="flex items-center gap-2 px-3 py-2 border-b border-zinc-200 dark:border-zinc-800">
            <svg class="w-5 h-5 text-zinc-500 dark:text-zinc-400 shrink-0" viewBox="0 0 24 24" fill="none">
              <path d="m21 21-4.3-4.3M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z"
                stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
            <h2 :id="titleId" class="sr-only">検索</h2>
            <input
              ref="inputRef"
              v-model="q"
              :placeholder="placeholder"
              class="w-full bg-transparent outline-none text-zinc-900 dark:text-zinc-50 placeholder-zinc-400 py-2"
              type="text"
              @input="onInput"
            />
          </div>

          <!-- Results -->
          <div class="max-h-[60vh] overflow-y-auto">
            <div v-if="loading" class="px-4 py-6 text-sm text-zinc-500">読み込み中…</div>

            <ul v-else-if="q.trim().length > 0 && results.length" role="listbox" :aria-activedescendant="activeDescId">
              <li
                v-for="(item, idx) in results"
                :key="itemKey(item, idx)"
                :id="optionId(idx)"
                :aria-selected="idx === active"
                role="option"
                @mouseenter="active = idx"
                @mouseleave="active = -1"
                @click="() => { select(item); PushToPage(item) }"
                class="cursor-pointer"
              >
                <div
                  class="flex items-center gap-3 px-4 py-3"
                  :class="idx === active ? 'bg-zinc-100 dark:bg-zinc-800/70' : 'hover:bg-zinc-50 dark:hover:bg-zinc-800/40'">
                  <div class="min-w-0 flex-1">
                    <p class="text-sm text-zinc-900 dark:text-zinc-50 truncate" v-html="highlight(toLabel(item), q)" />
                    <p v-if="toDesc(item)" class="text-xs text-zinc-500 dark:text-zinc-400 truncate">
                      {{ toDesc(item) }}
                    </p>
                  </div>
                </div>
              </li>
            </ul>

            <div v-else-if="historyToShow.length" class="py-2">
              <div class="px-4 pb-2 text-xs text-zinc-500 uppercase">最近の検索</div>
              <ul>
                <li
                  v-for="(h, idx) in historyToShow"
                  :key="`hist-${idx}-${h.query}`"
                  @click="applyHistory(h.query)"
                  class="group cursor-pointer"
                >
                  <div class="flex items-center justify-between gap-3 px-4 py-2 hover:bg-zinc-50 dark:hover:bg-zinc-800/40">
                    <div class="min-w-0 flex-1">
                      <p class="text-sm text-zinc-700 dark:text-zinc-200 truncate">{{ h.query }}</p>
                      <p class="text-xs text-zinc-500 dark:text-zinc-400">{{ h.when }}</p>
                    </div>
                    <button
                      class="opacity-0 group-hover:opacity-100 text-xs px-2 py-1 rounded border border-zinc-300 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800"
                      @click.stop="removeHistory(idx)"
                    >
                      削除
                    </button>
                  </div>
                </li>
              </ul>
            </div>

            <div v-else class="px-4 py-10 text-center text-sm text-zinc-500 dark:text-zinc-400">
              検索語を入力すると候補が表示されます。
            </div>
          </div>

          <!-- Footer -->
          <div class="px-4 py-2 border-t text-xs text-zinc-500 dark:text-zinc-400 flex justify-between">
            <div>↑↓ で移動 / Enter で決定 / ESC で閉じる</div>
            <button @click="clearHistory" v-if="historyToShow.length" class="underline">履歴を全削除</button>
          </div>
        </div>
      </div>
    </transition>
  </teleport>
</template>

<script setup>
import { ref, computed, watch, onMounted, onBeforeUnmount } from 'vue'
import { routerKey } from 'vue-router'
import { useRouter, useRoute } from 'vue-router'
const props = defineProps({
  modelValue: { type: Boolean, required: true },
  placeholder: { type: String, default: '検索…' },
  fetcher: { type: Function, required: true },
  toLabel: { type: Function, default: (x) => x?.label ?? '' },
  toDesc: { type: Function, default: (x) => x?.description ?? '' },
  initialQuery: { type: String, default: '' },
  historyLimit: { type: Number, default: 10 },
})
const emit = defineEmits(['update:modelValue', 'select'])
const router = useRouter();
const route = useRoute();
const q = ref(props.initialQuery)
const results = ref([])
const loading = ref(false)
const inputRef = ref(null)
const active = ref(-1)
const titleId = `search-dialog-${Math.random().toString(36).slice(2)}`
const optionId = (i) => `opt-${i}-${titleId}`
const activeDescId = computed(() => (active.value >= 0 ? optionId(active.value) : null))

const HISTORY_KEY = 'search_history'
const history = ref(loadHistory())
const historyToShow = computed(() => history.value.slice(0, props.historyLimit))

function loadHistory() {
  try {
    const raw = localStorage.getItem(HISTORY_KEY)
    return raw ? JSON.parse(raw) : []
  } catch {
    return []
  }
}
function saveHistory(list) {
  try {
    localStorage.setItem(HISTORY_KEY, JSON.stringify(list))
  } catch {}
}
function pushHistory(query) {
  const trimmed = query.trim()
  if (!trimmed) return
  const filtered = history.value.filter((x) => x.query !== trimmed)
  history.value = [{ query: trimmed, when: new Date().toLocaleString() }, ...filtered].slice(0, props.historyLimit)
  saveHistory(history.value)
}
function applyHistory(query) {
  q.value = query
  onInput()
}
function removeHistory(idx) {
  history.value.splice(idx, 1)
  saveHistory(history.value)
}
function clearHistory() {
  history.value = []
  saveHistory(history.value)
}
// const itemKey = (item, idx) => item?.id ?? `item-${idx}`
const itemKey = (item, idx) => {
  return item?.id ?? `item-${idx}`
}
async function onInput() {
  const term = q.value.trim()
  if (!term) {
    results.value = []
    return
  }
  loading.value = true
  try {
    results.value = await props.fetcher(term)
  } catch {
    results.value = []
  } finally {
    loading.value = false
  }
}

function select(item) {
  pushHistory(props.toLabel(item))
  emit('select', item)
  close()
}

function move(d) {
  const n = results.value.length
  if (!n) return
  active.value = (active.value + d + n) % n
}

function enter() {
  if (results.value.length && active.value >= 0) {
    select(results.value[active.value])
  }
}

function close() {
  emit('update:modelValue', false)
}

// function highlight(text, query) {
//   const t = String(text ?? '')
//   const qy = String(query ?? '').trim()
//   if (!qy) return escapeHtml(t)
//   try {
//     const re = new RegExp(qy.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'ig')
//     return escapeHtml(t).replace(re, (m) => `<mark>${m}</mark>`)
//   } catch {
//     return escapeHtml(t)
//   }
// }
function highlight(text, query){
  const t = String(text ?? '')
  const qy = String(query ?? '').trim()
  if (!qy) return escapeHtml(t)

  try {
    const re = new RegExp(qy.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'ig')

    // HTMLエスケープする前にマッチ対象を <mark> で囲む
    const highlighted = t.replace(re, (match) => `<<<MARK>>>${match}<<<ENDMARK>>>`)

    // エスケープ処理を後で実行し、マークを戻す
    return escapeHtml(highlighted)
      .replace(/&lt;&lt;&lt;MARK&gt;&gt;&gt;/g, '<mark>')
      .replace(/&lt;&lt;&lt;ENDMARK&gt;&gt;&gt;/g, '</mark>')
  } catch {
    return escapeHtml(t)
  }
}
function escapeHtml(s) {
  return s.replace(/[&<>"']/g, (m) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[m]))
}

function lockScroll() {
  if (process.client) document.documentElement.style.overflow = 'hidden'
}
function unlockScroll() {
  if (process.client) document.documentElement.style.overflow = ''
}

let prevFocus = null
watch(
  () => props.modelValue,
  (open) => {
    if (open) {
      prevFocus = document.activeElement
      lockScroll()
      setTimeout(() => inputRef.value?.focus(), 0)
    } else {
      unlockScroll()
      prevFocus?.focus?.()
      active.value = -1
    }
  },
  { immediate: true },
)

onMounted(() => { if (props.modelValue) lockScroll() })
onBeforeUnmount(() => { unlockScroll() })

function PushToPage(key){
  const item = props.toDesc(key);
  try {
    if (item === 'ライブラリ'){
      return router.push(`/library/${key.data.id}`);
    }else{
      return router.push(`/studio/${key.data.id}`);
    }
  } catch (error) {
    console.error('サーバーからのエラー：', error);
    throw error;
  }
}

</script>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.15s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
.pop-enter-active, .pop-leave-active {
  transition: transform 0.15s ease, opacity 0.15s ease;
}
.pop-enter-from, .pop-leave-to {
  opacity: 0;
  transform: translateY(4px) scale(0.98);
}
</style>
