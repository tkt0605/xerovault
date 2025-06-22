import { useAuthStore } from "./auth";
import { useAuthGroups } from "./group";
import { useRuntimeConfig } from "#app";


export const useAuthLibrary = defineStore('library', {
    state: () => ({
        libraries: [],
    }),
    actions: {
        async CreateLibraries(name, tag, is_public){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}librarys/`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    },
                    body: JSON.stringify({
                        name: name.trim(),
                        tag: tag.trim(),
                        is_public: is_public
                    })
                });
                if (!response.ok){
                    const errorData = await response.json();
                    throw Error(errorData.detail || 'ライブラリ作成失敗')
                }
                const data = await response.json();
                return {
                    id: data.id,
                    name: data.name,
                    tag: data.tag,
                    is_public: data.is_public,
                    owner: data.owner,
                    created_at: data.created_at,
                    updated_at: data.updated_at,
                }
            }catch(error){
                console.error('ライブラリ作成失敗', error);
                throw error;
            }
        },
        async FetchLibrary(){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}librarys/`, {
                    method: "GET",
                    headers: {
                        "Content-type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok){
                    const errorData = await response.json();
                    throw Error(errorData.detail || "ライブラリ取得失敗");
                }
                const data = await response.json();
                if (!Array.isArray(data)){
                    return {
                        id: data.id,
                        name: data.name,
                        tag: data.tag,
                        owner: data.owner,
                        is_public: data.is_public,
                        created_at: data.created_at,
                        updated_at: data.updated_at
                    }
                }
                return data.map((item) => ({
                    id: item.id,
                    name: item.name,
                    tag: item.tag,
                    is_public: item.is_public,
                    owner: item.owner,
                    created_at: item.created_at,
                    updated_at: item.updated_at
                }));
            }catch(error){
                console.error('ライブラリ情報取得のしっぱい');
                throw error;
            }
        },
        async FetchLibraryId(id){
            const config = useRuntimeConfig();
            const authStore = useAuthStore();
            try{
                const response = await fetch(`${config.public.apiBase}librarys/${id}`, {
                    method: "GET",
                    headers: {
                        "Content-type": "application/json",
                        "Authorization": `Bearer ${authStore.accessToken}`
                    }
                });
                if (!response.ok){
                    const errorData = await response.json();
                    throw Error(errorData.detail || '個別ライブラリ情報取得失敗')
                }
                const data = await response.json();
                if (!Array.isArray(data)){
                    return {
                        id: data.id,
                        name: data.name,
                        tag: data.tag,
                        is_public: data.is_public,
                        owner: data.owner,
                        created_at: data.created_at,
                        updated_at: data.updated_at
                    }
                }
                return data.map((item) => ({
                    id: item.id,
                    name: item.name,
                    tag: item.tag,
                    owner: item.owner,
                    is_public: item.is_public,
                    created_at: item.created_at,
                    updated_at: item.updated_at
                }));
            }catch(error){
                console.error('個別ライブラリ取得失敗', error);
                throw error;
            }
        }
    },
    getters: {

    }
});
