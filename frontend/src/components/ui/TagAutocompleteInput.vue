<template>
  <div class="relative">
    <BaseInput
      :model-value="modelValue"
      :placeholder="placeholder"
      @update:model-value="(v) => emit('update:modelValue', String(v))"
      @focus="focused = true"
      @blur="focused = false"
    />
    <div
      v-if="focused && suggestions.length"
      class="absolute z-10 mt-1 w-full overflow-hidden rounded-control border border-line bg-paper-raised shadow-card"
    >
      <button
        v-for="s in suggestions"
        :key="s.tag"
        type="button"
        class="flex w-full items-center justify-between px-3 py-1.5 text-left text-sm text-ink-soft hover:bg-paper-sunken"
        @mousedown.prevent="selectSuggestion(s.tag)"
      >
        <span>#{{ s.tag }}</span>
        <span class="text-xs text-ink-faint">{{ s.usageCount }}</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { TagSuggestion } from '@sodalis/shared'
import { rpc } from '@/lib/rpc'
import BaseInput from './BaseInput.vue'

const props = defineProps<{ modelValue: string; placeholder?: string }>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()

const allTags = ref<TagSuggestion[]>([])
const focused = ref(false)

onMounted(async () => {
  allTags.value = await rpc<TagSuggestion[]>('get_all_tags', { p_limit: 100 })
})

function currentFragment(): string {
  const parts = props.modelValue.split(',')
  return parts[parts.length - 1].trim()
}

const suggestions = computed(() => {
  const fragment = currentFragment()
  if (!fragment) return []
  const selected = new Set(
    props.modelValue
      .split(',')
      .map((t) => t.trim())
      .filter(Boolean)
  )
  return allTags.value.filter((t) => t.tag.includes(fragment) && !selected.has(t.tag)).slice(0, 8)
})

function selectSuggestion(tag: string): void {
  const parts = props.modelValue.split(',')
  parts[parts.length - 1] = parts.length > 1 ? ` ${tag}` : tag
  emit('update:modelValue', `${parts.join(',')}, `)
}
</script>
