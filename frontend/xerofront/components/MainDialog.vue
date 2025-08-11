<!-- <template>
  <div v-if="visible" class="fixed inset-0 z-50 flex items-center justify-center backdrop-blur-sm bg-black/40">
    <div class="bg-white dark:bg-zinc-800 w-[90%] max-w-lg rounded-xl shadow-xl border dark:border-zinc-700 border-zinc-200">
      <div class="flex items-center justify-between px-6 py-4 border-b dark:border-zinc-700 border-zinc-200">
        <slot name="header">
          <h2 class="text-lg font-semibold text-zinc-100">ダイアログ</h2>
        </slot>
        <button @click="$emit('close')" class="text-zinc-400 hover:text-red-500 transition" aria-label="閉じる">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-x-lg" viewBox="0 0 16 16">
            <path d="M2.146 2.146a.5.5 0 0 1 .708 0L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8 2.146 2.854a.5.5 0 0 1 0-.708z"/>
          </svg>
        </button>
      </div>
      <div class="p-6">
        <slot>
          <p class="text-zinc-300">ここに内容を挿入してください。</p>
        </slot>
      </div>
      <div class="px-6 py-4 border-t dark:border-zinc-700 border-zinc-200 flex justify-end gap-3">
        <slot name="footer" />
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  visible: Boolean
});
defineEmits(['close']);
</script> -->
      <!-- ヘッダー -->
<template>
  <Teleport to="body">
    <div
      v-if="visible"
      class="fixed inset-0 z-[700] dark:text-white text-zinc-900 "
      @keydown.esc.prevent="onEsc"
    >
      <!-- Backdrop -->
      <div
        class="absolute inset-0 bg-black/50 backdrop-blur-sm"
        @click="closeOnBackdrop ? emitClose() : null"
      />

      <!-- Panel wrapper: center on md+, bottom-sheet on <md -->
      <div class="absolute inset-0 flex items-end md:items-center justify-center p-2 sm:p-4">
        <div
          ref="panelRef"
          role="dialog"
          :aria-modal="true"
          :aria-labelledby="titleId"
          tabindex="-1"
          @click.stop
          class="w-full md:w-[90%] bg-white dark:bg-zinc-900 border border-zinc-200 dark:border-zinc-800 shadow-2xl
                 transition-all duration-200 ease-out
                 outline-none
                 md:rounded-2xl
                 overflow-hidden
                 max-h-[92vh] md:max-h-[80vh]
                 transform
                 data-[entering=true]:opacity-0 data-[entering=true]:md:scale-95
                 data-[entering=true]:translate-y-2 md:data-[entering=true]:translate-y-0"
          :class="[
            sizeClass,
            fullscreenOnMobile ? 'rounded-t-2xl md:rounded-2xl' : 'rounded-t-xl md:rounded-2xl',
            fullscreenOnMobile ? 'h-[92vh] md:h-[70vh]' : ''
          ]"
          :data-entering="entering"
        >
          <!-- Header -->
          <div class="flex items-center justify-between px-4 sm:px-6 py-3 sm:py-4 border-b border-zinc-200 dark:border-zinc-800">
            <slot name="header">
              <h2
                :id="titleId"
                class="text-base sm:text-lg md:text-xl font-semibold text-zinc-900 dark:text-zinc-100"
              >
                ダイアログ
              </h2>
            </slot>
            <button
              @click="emitClose"
              class="p-2 -m-2 rounded-lg text-zinc-500 hover:text-red-500 hover:bg-zinc-100 dark:hover:bg-zinc-800 transition"
              aria-label="閉じる"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor"
                   class="bi bi-x-lg" viewBox="0 0 16 16">
                <path
                  d="M2.146 2.146a.5.5 0 0 1 .708 0L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8 2.146 2.854a.5.5 0 0 1 0-.708z" />
              </svg>
            </button>
          </div>

          <!-- Content (scrolls independently) -->
          <div class="px-4 sm:px-6 py-4 overflow-y-auto">
            <slot>
              <p class="text-zinc-700 dark:text-zinc-300">ここに内容を挿入してください。</p>
            </slot>
          </div>

          <!-- Footer -->
          <div class="px-4 sm:px-6 py-3 sm:py-4 border-t border-zinc-200 dark:border-zinc-800 flex flex-col sm:flex-row sm:justify-end gap-2 sm:gap-3">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch, nextTick } from 'vue'

const props = withDefaults(defineProps<{
  visible: boolean
  size?: 'sm' | 'md' | 'lg' | 'xl'
  closeOnBackdrop?: boolean
  fullscreenOnMobile?: boolean
}>(), {
  size: 'md',
  closeOnBackdrop: true,
  fullscreenOnMobile: true
})

const emit = defineEmits<{
  (e: 'close'): void
}>()

const emitClose = () => emit('close')

const sizeClass = computed(() => {
  // Width only changes for md+; on mobile it fills width
  switch (props.size) {
    case 'sm': return 'md:max-w-sm'
    case 'lg': return 'md:max-w-2xl'
    case 'xl': return 'md:max-w-3xl'
    default:   return 'md:max-w-xl'
  }
})

const titleId = `dialog-title-${Math.random().toString(36).slice(2)}`
const panelRef = ref<HTMLElement | null>(null)
const entering = ref(false)

// Lock body scroll while open
const lock = () => document.documentElement.classList.add('overflow-hidden', 'md:pr-[var(--removed-body-scrollbar-size,0px)]')
const unlock = () => document.documentElement.classList.remove('overflow-hidden', 'md:pr-[var(--removed-body-scrollbar-size,0px)]')

// Focus the panel when opened
const focusPanel = async () => {
  await nextTick()
  panelRef.value?.focus()
}

const onEsc = () => emitClose()

// Animate-in flag
watch(() => props.visible, (v) => {
  if (v) {
    entering.value = true
    lock()
    focusPanel()
    // clear entering after a frame
    requestAnimationFrame(() => { entering.value = false })
  } else {
    unlock()
  }
})

onMounted(() => {
  if (props.visible) lock()
})
onUnmounted(() => unlock())
</script>

<style scoped>
/* Mobile bottom-sheet entrance */
[data-entering="true"] {
  /* initial state handled via transform classes in template */
}
</style>
