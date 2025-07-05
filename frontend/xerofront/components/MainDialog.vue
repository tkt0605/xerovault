<template>
  <div v-if="visible" class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
    <div class="bg-white dark:bg-zinc-800 p-6 rounded-xl shadow-lg max-w-md w-full">
      <slot name="header">
        <h2 class="text-lg font-semibold mb-4">デフォルトタイトル</h2>
      </slot>

      <slot>
        <div>内容がここに入ります。</div>
      </slot>

      <div class="mt-6 flex justify-end gap-3">
        <!-- <button @click="$emit('close')" class="bg-gray-300 hover:bg-gray-400 px-4 py-2 rounded">閉じる</button> -->
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
