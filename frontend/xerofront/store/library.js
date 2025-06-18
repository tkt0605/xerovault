import { useAuthStore } from "./auth";
import { useAuthGroups } from "./group";
import { useRuntimeConfig } from "#app";


export const useAuthLibrary = defineStore('library', {
    state: () => ({
        libraries: [],
    }),
    actions: {
        async CreateLibraries(){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}librarys/`)
            }catch(error){

            }
        },
    },
    getters: {

    }
});
