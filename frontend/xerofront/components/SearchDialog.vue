<template>
  <!-- Backdrop -->
  <transition name="fade">
    <div
      v-if="modelValue"
      class="fixed inset-0 z-[100] bg-black/50 backdrop-blur-sm"
      @click.self="close()"
    />
  </transition>

  <!-- Dialog -->
  <transition name="pop">
    <div
      v-if="modelValue"
      class="fixed inset-0 z-[101] flex items-start justify-center p-4 md:pt-20"
      role="dialog"
      aria-modal="true"
      aria-labelledby="search-dialog-title"
      @keydown.esc.prevent.stop="close()"
      @keydown.down.prevent="move(1)"
      @keydown.up.prevent="move(-1)"
      @keydown.enter.prevent="enter()"
    >
      <div
        class="w-full max-w-2xl rounded-2xl bg-white dark:bg-zinc-900 shadow-2xl ring-1 ring-black/10 dark:ring-white/10 overflow-hidden"
      >
        <!-- Header / Input -->
        <div class="flex items-center gap-2 px-3 py-2 border-b border-zinc-200 dark:border-zinc-800">
          <svg class="w-5 h-5 text-zinc-500 dark:text-zinc-400 shrink-0" viewBox="0 0 24 24" fill="none">
            <path d="m21 21-4.3-4.3M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z"
                  stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
          <input
            ref="inputRef"
            v-model="q"
            :placeholder="placeholder"
            class="w-full bg-transparent outline-none text-zinc-900 dark:text-zinc-50 placeholder-zinc-400 py-2"
            type="text"
            autocomplete="off"
            spellcheck="false"
            @input="onInput"
          />
          <kbd class="hidden md:inline-flex text-xs px-1.5 py-0.5 rounded border border-zinc-300 dark:border-zinc-700 text-zinc-500 dark:text-zinc-400">
            Esc
          </kbd>
        </div>

        <!-- Results / History -->
        <div class="max-h-[60vh] overflow-y-auto">
          <!-- Loading -->
          <div v-if="loading" class="px-4 py-6 text-sm text-zinc-500 dark:text-zinc-400">
            読み込み中…
          </div>

          <!-- サジェスト -->
          <ul v-else-if="q.trim().length > 0 && results.length > 0" role="listbox">
            <li
              v-for="(item, idx) in results"
              :key="itemKey(item, idx)"
              :id="optionId(idx)"
              :aria-selected="idx === active"
              role="option"
              @mouseenter="active = idx"
              @mouseleave="active = -1"
              @click="select(item)"
              class="cursor-pointer"
            >
              <div
                class="flex items-center gap-3 px-4 py-3"
                :class="idx === active ? 'bg-zinc-100 dark:bg-zinc-800/70' : 'hover:bg-zinc-50 dark:hover:bg-zinc-800/40'"
              >
                <div class="min-w-0 flex-1">
                  <p class="text-sm text-zinc-900 dark:text-zinc-50 truncate" v-html="highlight(itemLabel(item), q)"></p>
                  <p v-if="itemDescription(item)" class="text-xs text-zinc-500 dark:text-zinc-400 truncate">
                    {{ itemDescription(item) }}
                  </p>
                </div>
                <button
                  class="text-xs px-2 py-1 rounded border border-zinc-300 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800"
                  @click.stop="emitSubmit(itemLabel(item))"
                >
                  検索
                </button>
              </div>
            </li>
          </ul>

          <!-- 履歴 -->
          <div v-else-if="historyToShow.length > 0" class="py-2">
            <div class="px-4 pb-2 text-xs uppercase tracking-wide text-zinc-500 dark:text-zinc-400">
              最近の検索
            </div>
            <ul>
              <li
                v-for="(h, idx) in historyToShow"
                :key="`hist-${idx}-${h.query}`"
                class="group cursor-pointer"
                @click="applyHistory(h.query)"
              >
                <div
                  class="flex items-center justify-between gap-3 px-4 py-2 hover:bg-zinc-50 dark:hover:bg-zinc-800/40"
                >
                  <div class="min-w-0 flex-1">
                    <p class="text-sm text-zinc-700 dark:text-zinc-200 truncate">{{ h.query }}</p>
                    <p v-if="h.when" class="text-xs text-zinc-500 dark:text-zinc-400">{{ h.when }}</p>
                  </div>
                  <button
                    class="opacity-0 group-hover:opacity-100 text-xs px-2 py-1 rounded border border-zinc-300 dark:border-zinc-700 text-zinc-600 dark:text-zinc-300 hover:bg-zinc-100 dark:hover:bg-zinc-800"
                    @click.stop="removeHistory(idx)"
                    title="履歴から削除"
                  >
                    削除
                  </button>
                </div>
              </li>
            </ul>
          </div>

          <!-- Empty state -->
          <div v-else class="px-4 py-10 text-center text-sm text-zinc-500 dark:text-zinc-400">
            検索語を入力すると候補が表示されます。
          </div>
        </div>

        <!-- Footer -->
        <div class="flex items-center justify-between px-4 py-2 border-t border-zinc-200 dark:border-zinc-800 text-xs text-zinc-500 dark:text-zinc-400">
          <div class="flex items-center gap-4">
            <div class="flex items-center gap-1">
              <span class="inline-flex items-center justify-center w-5 h-5 rounded border border-zinc-300 dark:border-zinc-700">↑</span>
              <span class="inline-flex items-center justify-center w-5 h-5 rounded border border-zinc-300 dark:border-zinc-700">↓</span>
              で移動
            </div>
            <div class="flex items-center gap-1">
              <span class="inline-flex items-center justify-center px-1.5 h-5 rounded border border-zinc-300 dark:border-zinc-700">Enter</span>
              で決定
            </div>
          </div>
          <button class="underline hover:no-underline" @click="clearHistory" v-if="historyToShow.length">履歴を全削除</button>
        </div>
      </div>
    </div>
  </transition>
</template>

<script setup>
import { ref, watch, onMounted, onBeforeUnmount, computed, nextTick } from 'vue'

/**
 * Props
 * - modelValue: v-model 開閉
 * - placeholder: プレースホルダー
 * - fetcher: 非同期サジェスト取得関数 (q: string) => Promise<Array>
 * - toLabel / toDesc / toKey: 結果→表示用の変換関数
 * - history: [{ query, when? }] 初期履歴（省略時は localStorage から読み込み）
 * - historyKey: localStorage キー
 * - initialQuery: 初期入力値
 * - debounceMs: デバウンス時間
 * - maxHistory: 履歴最大件数
 */
const props = defineProps({
  modelValue: { type: Boolean, default: false },
  placeholder: { type: String, default: '検索…' },
  fetcher: { type: Function, default: null },
  toLabel: { type: Function, default: (x) => (typeof x === 'string' ? x : x?.label ?? '') },
  toDesc: { type: Function, default: (x) => x?.description ?? '' },
  toKey: { type: Function, default: (x, i) => (x?.id ?? x?.key ?? i) },
  history: { type: Array, default: () => [] },
  historyKey: { type: String, default: 'search_dialog_history' },
  initialQuery: { type: String, default: '' },
  debounceMs: { type: Number, default: 200 },
  maxHistory: { type: Number, default: 15 },
})

/**
 * Emits
 * - update:modelValue(Boolean) : 開閉
 * - select(item)               : 結果選択
 * - submit(query)              : 「検索」実行
 * - close()                    : 閉じた通知
 */
const emit = defineEmits(['update:modelValue', 'select', 'submit', 'close'])

const q = ref(props.initialQuery)
const results = ref([])
const loading = ref(false)
const active = ref(-1)
const inputRef = ref(null)

let timer = null

const itemLabel = (item) => props.toLabel(item)
const itemDescription = (item) => props.toDesc(item)
const itemKey = (item, i) => props.toKey(item, i)
const optionId = (idx) => `sd-opt-${idx}`

/** 履歴（localStorage+props） */
const historyState = ref(loadHistory())

const historyToShow = computed(() => {
  return historyState.value.slice(0, props.maxHistory)
})

function loadHistory () {
  try {
    const fromLS = JSON.parse(localStorage.getItem(props.historyKey) || '[]')
    const merged = [...props.history, ...fromLS]
    // 重複除去（先頭優先）
    const seen = new Set()
    const out = []
    for (const h of merged) {
      if (!h?.query) continue
      if (seen.has(h.query)) continue
      seen.add(h.query)
      out.push({ query: h.query, when: h.when })
    }
    return out
  } catch (e) {
    return props.history ?? []
  }
}

function saveHistory () {
  try {
    localStorage.setItem(props.historyKey, JSON.stringify(historyState.value))
  } catch (e) {}
}

function pushHistory (query) {
  if (!query || !query.trim()) return
  const trimmed = query.trim()
  const now = new Date()
  // 既存削除して先頭へ
  historyState.value = [{ query: trimmed, when: prettyTime(now) }]
    .concat(historyState.value.filter(h => h.query !== trimmed))
    .slice(0, props.maxHistory)
  saveHistory()
}

function removeHistory (idx) {
  historyState.value.splice(idx, 1)
  saveHistory()
}

function clearHistory () {
  historyState.value = []
  saveHistory()
}

function prettyTime (d) {
  // 簡易的な相対表示
  const diff = (Date.now() - d.getTime()) / 1000
  if (diff < 60) return 'たった今'
  if (diff < 3600) return `${Math.floor(diff / 60)}分前`
  if (diff < 86400) return `${Math.floor(diff / 3600)}時間前`
  return `${d.getFullYear()}/${d.getMonth() + 1}/${d.getDate()}`
}

/** 入力のたびにデバウンスして fetcher 実行 */
function onInput () {
  active.value = -1
  if (!props.fetcher) return
  if (timer) clearTimeout(timer)
  const query = q.value
  if (!query.trim()) {
    results.value = []
    loading.value = false
    return
  }
  timer = setTimeout(async () => {
    loading.value = true
    try {
      const res = await props.fetcher(query)
      results.value = Array.isArray(res) ? res : []
    } catch (e) {
      results.value = []
    } finally {
      loading.value = false
    }
  }, props.debounceMs)
}

/** キーボード移動 */
function move (delta) {
  const total = results.value.length
  if (!total) return
  if (active.value < 0) {
    active.value = delta > 0 ? 0 : total - 1
  } else {
    active.value = (active.value + delta + total) % total
  }
  scrollActiveIntoView()
}

/** Enter: アクティブアイテム or 検索 */
function enter () {
  if (active.value >= 0 && active.value < results.value.length) {
    select(results.value[active.value])
    return
  }
  emitSubmit(q.value)
}

/** 結果選択 */
function select (item) {
  emit('select', item)
  pushHistory(itemLabel(item))
  close()
}

/** 検索確定（Enter / 検索ボタン） */
function emitSubmit (query) {
  const qq = (query ?? q.value ?? '').trim()
  if (!qq) return
  emit('submit', qq)
  pushHistory(qq)
  close()
}

/** 履歴をクリックで適用（即検索ではなく入力に反映） */
function applyHistory (query) {
  q.value = query
  nextTick(() => onInput())
}

/** フォーカス管理 */
watch(() => props.modelValue, async (v) => {
  if (v) {
    await nextTick()
    inputRef.value?.focus()
    document.documentElement.classList.add('overflow-hidden')
    document.body.classList.add('overflow-hidden')
  } else {
    document.documentElement.classList.remove('overflow-hidden')
    document.body.classList.remove('overflow-hidden')
  }
})

/** 開閉（v-model） */
function close () {
  emit('update:modelValue', false)
  emit('close')
}

/** アクティブ項目が見えるようにスクロール */
function scrollActiveIntoView () {
  const id = optionId(active.value)
  const el = document.getElementById(id)
  if (!el) return
  const container = el.closest('[role="listbox"]')
  if (!container) return
  const cTop = container.scrollTop
  const cBottom = cTop + container.clientHeight
  const eTop = el.offsetTop
  const eBottom = eTop + el.clientHeight
  if (eTop < cTop) container.scrollTop = eTop
  else if (eBottom > cBottom) container.scrollTop = eBottom - container.clientHeight
}

onMounted(() => {
  // 初期開時にフォーカス
  if (props.modelValue) {
    nextTick(() => inputRef.value?.focus())
  }
})

onBeforeUnmount(() => {
  if (timer) clearTimeout(timer)
  document.documentElement.classList.remove('overflow-hidden')
  document.body.classList.remove('overflow-hidden')
})

/** ハイライト（簡易版） */
function escapeReg (s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
}
function highlight (text, q) {
  if (!text) return ''
  if (!q) return text
  const re = new RegExp(`(${escapeReg(q)})`, 'ig')
  return text.replace(re, '<mark class="bg-yellow-200 dark:bg-yellow-600/60 px-0.5 rounded">$1</mark>')
}
</script>

<style scoped>
.fade-enter-active, .fade-leave-active { transition: opacity .15s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }
.pop-enter-active, .pop-leave-active { transition: transform .18s ease, opacity .18s ease; }
.pop-enter-from, .pop-leave-to { transform: translateY(8px) scale(0.98); opacity: 0; }
</style>
