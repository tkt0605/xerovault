import { defineStore } from 'pinia'
import { ref } from 'vue'

const MOBILE_BREAKPOINT = '(min-width: 768px)'

export const useUiStore = defineStore('ui', () => {
  const asideOpen = ref(
    typeof window === 'undefined' ? true : window.matchMedia(MOBILE_BREAKPOINT).matches
  )
  const showCreateGroupDialog = ref(false)

  function toggleAside(): void {
    asideOpen.value = !asideOpen.value
  }

  function closeAsideOnMobile(): void {
    if (typeof window !== 'undefined' && !window.matchMedia(MOBILE_BREAKPOINT).matches) {
      asideOpen.value = false
    }
  }

  function openCreateGroupDialog(): void {
    showCreateGroupDialog.value = true
    closeAsideOnMobile()
  }

  return {
    asideOpen,
    toggleAside,
    closeAsideOnMobile,
    showCreateGroupDialog,
    openCreateGroupDialog,
  }
})
