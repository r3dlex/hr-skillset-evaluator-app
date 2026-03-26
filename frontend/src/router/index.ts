import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes: RouteRecordRaw[] = [
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: { public: true },
  },
  {
    path: '/',
    redirect: '/dashboard',
  },
  {
    path: '/dashboard',
    name: 'dashboard',
    component: () => import('@/views/DashboardRouter.vue'),
  },
  {
    path: '/skillsets/:id',
    name: 'skillset',
    component: () => import('@/views/SkillsetView.vue'),
    props: true,
  },
  {
    path: '/self-evaluation/:skillsetId',
    name: 'self-evaluation',
    component: () => import('@/views/SelfEvaluationView.vue'),
    props: true,
  },
  {
    path: '/settings/skillsets',
    name: 'settings',
    component: () => import('@/views/SettingsView.vue'),
    meta: { requiresManager: true },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to, _from, next) => {
  const authStore = useAuthStore()

  // Try to fetch user if not yet loaded
  if (!authStore.isAuthenticated && !to.meta.public) {
    await authStore.fetchMe()
  }

  // Public routes are always accessible
  if (to.meta.public) {
    if (authStore.isAuthenticated) {
      next('/dashboard')
    } else {
      next()
    }
    return
  }

  // Protected routes require authentication
  if (!authStore.isAuthenticated) {
    next('/login')
    return
  }

  // Manager-only routes
  if (to.meta.requiresManager && !authStore.isManager) {
    next('/dashboard')
    return
  }

  next()
})

export default router
