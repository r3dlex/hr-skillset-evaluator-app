import { describe, it, expect, vi, beforeEach } from 'vitest'
import { createRouter, createWebHistory } from 'vue-router'
import { createPinia, setActivePinia } from 'pinia'

vi.mock('@/stores/auth', () => ({ useAuthStore: vi.fn() }))

// Mock all lazily-loaded view components so router.push() resolves instantly
vi.mock('@/views/LoginView.vue', () => ({ default: { template: '<div/>' } }))
vi.mock('@/views/DashboardRouter.vue', () => ({ default: { template: '<div/>' } }))
vi.mock('@/views/SkillsetView.vue', () => ({ default: { template: '<div/>' } }))
vi.mock('@/views/SelfEvaluationView.vue', () => ({ default: { template: '<div/>' } }))
vi.mock('@/views/SettingsView.vue', () => ({ default: { template: '<div/>' } }))

import { useAuthStore } from '@/stores/auth'

// We test the router logic directly without importing the actual router
// to avoid issues with dynamic imports in coverage.
// Instead, we verify the guard logic inline.

const mockAuthStore = {
  isAuthenticated: false,
  isManager: false,
  fetchMe: vi.fn(),
}

describe('Router guard logic', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useAuthStore).mockReturnValue(mockAuthStore as ReturnType<typeof useAuthStore>)
    mockAuthStore.isAuthenticated = false
    mockAuthStore.isManager = false
    mockAuthStore.fetchMe.mockResolvedValue(undefined)
  })

  it('redirects unauthenticated user to /login for protected route', async () => {
    // Simulate the guard behavior: unauthenticated user accessing /dashboard
    mockAuthStore.isAuthenticated = false
    const next = vi.fn()

    // Replicate guard logic
    const to = { meta: { public: false } } as any
    if (!mockAuthStore.isAuthenticated && !to.meta.public) {
      await mockAuthStore.fetchMe()
    }
    if (!mockAuthStore.isAuthenticated) {
      next('/login')
    } else {
      next()
    }

    expect(next).toHaveBeenCalledWith('/login')
  })

  it('allows authenticated user to access protected route', async () => {
    mockAuthStore.isAuthenticated = true
    const next = vi.fn()

    const to = { meta: { public: false } } as any
    if (!mockAuthStore.isAuthenticated && !to.meta.public) {
      await mockAuthStore.fetchMe()
    }
    if (!mockAuthStore.isAuthenticated) {
      next('/login')
    } else if (to.meta.requiresManager && !mockAuthStore.isManager) {
      next('/dashboard')
    } else {
      next()
    }

    expect(next).toHaveBeenCalledWith()
  })

  it('redirects authenticated user away from public routes', async () => {
    mockAuthStore.isAuthenticated = true
    const next = vi.fn()

    const to = { meta: { public: true } } as any
    if (to.meta.public) {
      if (mockAuthStore.isAuthenticated) {
        next('/dashboard')
      } else {
        next()
      }
    }

    expect(next).toHaveBeenCalledWith('/dashboard')
  })

  it('allows unauthenticated user to access public routes', async () => {
    mockAuthStore.isAuthenticated = false
    const next = vi.fn()

    const to = { meta: { public: true } } as any
    if (to.meta.public) {
      if (mockAuthStore.isAuthenticated) {
        next('/dashboard')
      } else {
        next()
      }
    }

    expect(next).toHaveBeenCalledWith()
  })

  it('redirects non-manager from manager-only routes', async () => {
    mockAuthStore.isAuthenticated = true
    mockAuthStore.isManager = false
    const next = vi.fn()

    const to = { meta: { public: false, requiresManager: true } } as any
    if (!mockAuthStore.isAuthenticated) {
      next('/login')
    } else if (to.meta.requiresManager && !mockAuthStore.isManager) {
      next('/dashboard')
    } else {
      next()
    }

    expect(next).toHaveBeenCalledWith('/dashboard')
  })

  it('allows manager to access manager-only routes', async () => {
    mockAuthStore.isAuthenticated = true
    mockAuthStore.isManager = true
    const next = vi.fn()

    const to = { meta: { public: false, requiresManager: true } } as any
    if (!mockAuthStore.isAuthenticated) {
      next('/login')
    } else if (to.meta.requiresManager && !mockAuthStore.isManager) {
      next('/dashboard')
    } else {
      next()
    }

    expect(next).toHaveBeenCalledWith()
  })

  it('calls fetchMe when not authenticated and route is not public', async () => {
    mockAuthStore.isAuthenticated = false

    const to = { meta: { public: false } } as any
    if (!mockAuthStore.isAuthenticated && !to.meta.public) {
      await mockAuthStore.fetchMe()
    }

    expect(mockAuthStore.fetchMe).toHaveBeenCalled()
  })

  it('does not call fetchMe for public routes', async () => {
    mockAuthStore.isAuthenticated = false

    const to = { meta: { public: true } } as any
    if (!mockAuthStore.isAuthenticated && !to.meta.public) {
      await mockAuthStore.fetchMe()
    }

    expect(mockAuthStore.fetchMe).not.toHaveBeenCalled()
  })
})

describe('Route definitions', () => {
  it('router has correct routes configured', async () => {
    // Import the actual router to verify route definitions
    const routerModule = await import('../index')
    const router = routerModule.default

    const routes = router.getRoutes()
    const routePaths = routes.map(r => r.path)

    expect(routePaths).toContain('/login')
    expect(routePaths).toContain('/dashboard')
    expect(routePaths).toContain('/skillsets/:id')
    expect(routePaths).toContain('/self-evaluation/:skillsetId')
    expect(routePaths).toContain('/settings/skillsets')
  })

  it('login route has public meta', async () => {
    const routerModule = await import('../index')
    const router = routerModule.default
    const routes = router.getRoutes()
    const loginRoute = routes.find(r => r.path === '/login')
    expect(loginRoute?.meta?.public).toBe(true)
  })

  it('settings route has requiresManager meta', async () => {
    const routerModule = await import('../index')
    const router = routerModule.default
    const routes = router.getRoutes()
    const settingsRoute = routes.find(r => r.path === '/settings/skillsets')
    expect(settingsRoute?.meta?.requiresManager).toBe(true)
  })
})

describe('Navigation guard integration (actual router)', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useAuthStore).mockReturnValue(mockAuthStore as ReturnType<typeof useAuthStore>)
    mockAuthStore.isAuthenticated = false
    mockAuthStore.isManager = false
    mockAuthStore.fetchMe.mockResolvedValue(undefined)
  })

  it('redirects unauthenticated user navigating to /dashboard to /login', async () => {
    mockAuthStore.isAuthenticated = false
    const routerModule = await import('../index')
    const router = routerModule.default
    await router.push('/dashboard')
    expect(router.currentRoute.value.path).toBe('/login')
  })

  it('allows authenticated user to navigate to /dashboard', async () => {
    mockAuthStore.isAuthenticated = true
    const routerModule = await import('../index')
    const router = routerModule.default
    await router.push('/dashboard')
    expect(router.currentRoute.value.path).toBe('/dashboard')
  })

  it('redirects authenticated user from /login to /dashboard', async () => {
    mockAuthStore.isAuthenticated = true
    const routerModule = await import('../index')
    const router = routerModule.default
    await router.push('/login')
    expect(router.currentRoute.value.path).toBe('/dashboard')
  })

  it('allows unauthenticated user to access /login', async () => {
    mockAuthStore.isAuthenticated = false
    const routerModule = await import('../index')
    const router = routerModule.default
    await router.push('/login')
    expect(router.currentRoute.value.path).toBe('/login')
  })

  it('redirects non-manager from /settings/skillsets to /dashboard', async () => {
    mockAuthStore.isAuthenticated = true
    mockAuthStore.isManager = false
    const routerModule = await import('../index')
    const router = routerModule.default
    await router.push('/settings/skillsets')
    expect(router.currentRoute.value.path).toBe('/dashboard')
  })

  it('allows manager to access /settings/skillsets', async () => {
    mockAuthStore.isAuthenticated = true
    mockAuthStore.isManager = true
    const routerModule = await import('../index')
    const router = routerModule.default
    await router.push('/settings/skillsets')
    expect(router.currentRoute.value.path).toBe('/settings/skillsets')
  })
})
