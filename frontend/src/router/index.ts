import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/auth/login',
      component: () => import('@/pages/auth/Login.vue'),
      meta: { public: true },
    },
    {
      path: '/auth/signup',
      component: () => import('@/pages/auth/Signup.vue'),
      meta: { public: true },
    },
    {
      path: '/auth/callback',
      component: () => import('@/pages/auth/AuthCallback.vue'),
      meta: { public: true },
    },
    { path: '/', component: () => import('@/pages/Home.vue') },
    { path: '/settings', component: () => import('@/pages/Settings.vue') },
    { path: '/group/:id', component: () => import('@/pages/group/GroupDetail.vue') },
    {
      path: '/group/:id/join',
      component: () => import('@/pages/group/JoinGroup.vue'),
      meta: { public: true },
    },
    {
      path: '/group/:id/request',
      component: () => import('@/pages/group/RequestJoin.vue'),
      meta: { public: true },
    },
    { path: '/group/:id/goal/:goalId', component: () => import('@/pages/group/GoalDetail.vue') },
    {
      path: '/group/:id/thread/:threadId',
      component: () => import('@/pages/group/ThreadDetail.vue'),
    },
    // クローズドβ期間中はグループ発見導線として隠す(Aside.vueのナビリンクも削除済み)。
    // 復活させる場合はここのコメントを外すこと
    // { path: '/ranking', component: () => import('@/pages/Ranking.vue'), meta: { public: true } },
  ],
})

router.beforeEach(async (to) => {
  if (to.meta.public) return true
  const auth = useAuthStore()
  if (!auth.isAuthenticated) {
    await auth.restoreSession()
    if (!auth.isAuthenticated) return '/auth/login'
  }
  return true
})

export default router
