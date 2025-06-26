import { defineStore } from "#imports";
import { useRuntimeConfig } from "#imports";
import { useRoute } from "vue-router";
import { useRouter } from "vue-router";
import { jwtDecode } from "jwt-decode";
import { jsx } from "vue/jsx-runtime";
import { resolveDynamicComponent } from "vue";


export const useAuthStore = defineStore("auth", {
    state: () => ({
        user: null,
        accessToken: null,
        refreshTokens: null,
        refreshTokenTimer: null,
    }),
    actions: {
        clearAuth() {
            this.user = null;
            this.accessToken = null;
            this.refreshTokenTimer = null;
            if (this.refreshTokenTimer) {
                clearTimeout(this.refreshTokenTimer);
                this.refreshTokenTimer = null;
            }
            localStorage.removeItem('access_token');
            localStorage.removeItem('refresh_token');
            localStorage.removeItem('user');
        },
        async refreshToken() {
            const config = useRuntimeConfig();
            const router = useRouter();
            const refreshTokens = localStorage.getItem('refresh_token');
            if (!refreshTokens) {
                console.error('リフレッシュトークンがありません。ログインしてくださ             try {
                const response = await fetch(`${config.public.apiBase}token/refresh/`, {
                    method: "POST",
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({ refresh: refreshTokens })
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    console.error('リフレッシュトークンの取得に失敗しました。', errorData);
                    router.push('/auth/login');
                    throw new Error(`リフレッシュトークンのエラー: ${errorData.detail}`);
                }
                const data = await response.json();
                this.accessToken = data.access;
                this.refreshTokens = data.refresh;
                localStorage.setItem("access_token", data.access);
                localStorage.setItem("refresh_token", data.refresh);
                this.scheduleTokenRefresh();
                console.log('リフレッシュトークンがリフレッシュされました。');
                return data.access;
            } catch (error) {
                console.error("リフレッシュトークン処理中のエラー:", error.message);
                router.push('/auth/login');
                throw error;
            }
        },
        async scheduleTokenRefresh() {
            if (this.refreshTokenTimer) {
                clearTimeout(this.refreshTokenTimer);
            }
            if (!this.accessToken) return;
            try {
                const decode = jwtDecode(this.accessToken);
                const exprisesAt = decode.exp * 1000;
                const now = Date.now();
                const refreshTime = exprisesAt - now - 60000;
                if (refreshTime > 0) {
                    this.refreshTokenTimer = setTimeout(() => {
                        this.refreshToken();
                    }, refreshTime);
                }
                console.log(`アクセストークンのリフレッシュをスケジュールしました: ${refreshTime / 1000}秒後`);

            } catch (error) {
                console.error('トークンのデコード中にエラーが発生:', error);
            }
        },
        async restoreSession() {
            if (process.server) return;
            const accessToken_const = localStorage.getItem("access_token");
            const refreshToken_const = localStorage.getItem('refresh_token');
            const setUser = JSON.parse(localStorage.getItem('user'));
            if (accessToken_const && refreshToken_const && setUser) {
                this.accessToken = accessToken_const;
                this.refreshTokens = refreshToken_const;
                this.user = setUser;
                this.scheduleTokenRefresh();
                try {
                    await this.refreshToken();
                } catch (error) {
                    console.error('トークン検証または、リフレッシュに失敗しました:', error);
                    this.clearAuth();
                }
            } else {
                this.clearAuth();
            }
        },
        async login(email, password) {
            const config = useRuntimeConfig();
            try {
                const response = await fetch(`${config.public.apiBase}token/`, {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                    },
                    body: JSON.stringify({
                        email: email.trim(),
                        password: password.trim(),
                    })
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.detail || "ログインエラーの発生");
                }
                const data = await response.json();

                this.accessToken = data.access;
                this.refreshTokens = data.refresh;
                const userResponse = await this.getUserInfo();
                this.user = userResponse.find((u) => u.email === email.trim());

                localStorage.setItem('access_token', this.accessToken);
                localStorage.setItem('refresh_token', this.refreshTokens);
                localStorage.setItem('user', JSON.stringify(this.user));
                return this.user;
            } catch (error) {
                console.error('ログインエラー:', error);
                throw error;
            }
        },
        async signup(email, password) {
            const config = useRuntimeConfig();
            try {
                const generateAvatar = (email) => {
                    return `https://api.dicebear.com/7.x/identicon/svg?seed=${email}`;
                };
                const response = await fetch(`${config.public.apiBase}signup/`, {
                    method: 'POST',
                    headers: {
                        "Content-Type": 'application/json'
                    },
                    body: JSON.stringify({
                        email: email.trim(),
                        password: password.trim(),
                        avater: generateAvatar(email),
                    }),
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw Error(errorData.detail || 'サインアップ失敗');
                }
                await this.login(email, password);
            } catch (error) {
                console.error('アカウント登録エラー：', error);
                throw error;
            }
        },
        async logout() {
            const config = useRuntimeConfig();
            try {
                const refreshTokens = this.refreshToken;
                const response = await fetch(`${config.public.apiBase}token/logout/`, {
                    method: 'POST',
                    headers: {
                        "Content-Type": 'application/json',
                    },
                    body: JSON.stringify({ refresh: refreshTokens }),
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw Error(errorData.detail || 'ログアウト失敗');
                }
                this.clearAuth();
                console.log('ログアウト成功');
            } catch (error) {
                console.error('ログアウトエラー', error);
                throw error;
            }
        },
        async getUserInfo() {
            const config = useRuntimeConfig();
            try {
                const response = await fetch(`${config.public.apiBase}users/`, {
                    method: "GET",
                    headers: {
                        "Content-Type": 'application/json',
                        'Authorization': `Bearer ${this.accessToken}`
                    },
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw Error(errorData.detail || 'ユーザー情報の取得失敗');
                }
                const data = await response.json();
                if (!Array.isArray(data)) {
                    return {
                        id: data.id,
                        email: data.email,
                        avater: data.avater,
                    };
                }
                return data.map((user) => ({
                    id: user?.id,
                    email: user?.email,
                    avater: user?.avater,
                }));
            } catch (error) {
                console.error('ユーザー情報取得エラー', error);
                throw error;
            }
        },
        async getUserinfoId(id) {
            const config = useRuntimeConfig();
            try {
                const response = await fetch(`${config.public.apiBase}users/${id}/`, {
                    method: "POST",
                    headers: {
                        "Content-Type": 'application/json',
                        'Authorization': `Bearer ${this.accessToken}`
                    }
                });
                if (!response.ok) {
                    const errorData = await response.json();
                    throw Error(errorData.detail || '個別ユーザー情報・取得失敗');
                }
                const data = await response.json();
                if (!Array.isArray(data)) {
                    return {
                        id: data.id,
                        email: data.email,
                        avater: data.avater
                    };
                }
                return {
                    id: item.id,
                    email: item.email,
                    avater: item.avater
                }
            } catch (error) {
                console.error('個別ユーザー情報・取得失敗', error);
                throw error;
            }
        },
    },
    getters: {
        isAuthenticated(state) {
            return !!state.accessToken;
        },
        currentUser(state) {
            const user = state.user;
            console.log('Vuex state User:', user);
            if (user && typeof user === "object") {
                return {
                    id: user.id,
                    email: user.email,
                    avater: user.avater,
                };
            }
            return null;
        }
    }
})
