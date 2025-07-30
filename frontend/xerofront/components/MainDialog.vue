<!-- <template>
  <div v-if="visible" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 ">
    <div class="bg-white dark:bg-zinc-800 p-6 rounded-xl shadow-lg max-w-md w-full">
      <slot name="header">
        <h2 class="text-lg font-semibold mb-4">デフォルトタイトル</h2>
      </slot>

      <slot>
        <div>内容がここに入ります。</div>
      </slot>

      <div class="mt-6 flex justify-end gap-3">
        <slot name="footer" />
      </div>
    </div>
  </div>
</template> -->
<template>
  <div v-if="visible" class="fixed inset-0 z-50 flex items-center justify-center backdrop-blur-sm bg-black/40">
    <div class="bg-white dark:bg-zinc-800 w-[90%] max-w-lg rounded-xl shadow-xl border border-zinc-700">
      <!-- ヘッダー -->
      <div class="flex items-center justify-between px-6 py-4 border-b border-zinc-600">
        <slot name="header">
          <h2 class="text-lg font-semibold text-zinc-100">ダイアログ</h2>
        </slot>
        <button @click="$emit('close')" class="text-zinc-400 hover:text-red-500 transition" aria-label="閉じる">
          <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="currentColor" class="bi bi-x-lg" viewBox="0 0 16 16">
            <path d="M2.146 2.146a.5.5 0 0 1 .708 0L8 7.293l5.146-5.147a.5.5 0 0 1 .708.708L8.707 8l5.147 5.146a.5.5 0 0 1-.708.708L8 8.707l-5.146 5.147a.5.5 0 0 1-.708-.708L7.293 8 2.146 2.854a.5.5 0 0 1 0-.708z"/>
          </svg>
        </button>
      </div>

      <!-- コンテンツ -->
      <div class="p-6">
        <slot>
          <p class="text-zinc-300">ここに内容を挿入してください。</p>
        </slot>
      </div>

      <!-- フッター -->
      <div class="px-6 py-4 border-t border-zinc-700 flex justify-end gap-3">
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
</script>
