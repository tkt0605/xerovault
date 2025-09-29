import { defineStore } from "#imports";
export const useAsideOpen = defineStore('aside', () => {
    const isAsideOpen = ref(false);
    const isSabAsideOpen = ref(false);

    const openAside = () => {
        isAsideOpen.value = true;
    };
    const closeAside = () => {
        isAsideOpen.value = false;
    };

    return {
        isAsideOpen,
        isSabAsideOpen,
        openAside,
        closeAside
    };
});