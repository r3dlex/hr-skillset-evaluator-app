import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import DashboardRouter from '../DashboardRouter.vue'

vi.mock('@/stores/auth', () => ({ useAuthStore: vi.fn() }))
vi.mock('@/composables/useScreenContext', () => ({
  useScreenContext: vi.fn().mockReturnValue({ setScreenContext: vi.fn() }),
}))

import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [{ path: '/', component: { template: '<div/>' } }],
})

describe('DashboardRouter', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('renders ManagerDashboard for managers', () => {
    vi.mocked(useAuthStore).mockReturnValue({ isManager: true } as ReturnType<typeof useAuthStore>)
    const wrapper = mount(DashboardRouter, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          ManagerDashboard: { template: '<div class="manager-dashboard"/>' },
          UserDashboard: { template: '<div class="user-dashboard"/>' },
        },
      },
    })
    expect(wrapper.find('.manager-dashboard').exists()).toBe(true)
    expect(wrapper.find('.user-dashboard').exists()).toBe(false)
  })

  it('renders UserDashboard for non-managers', () => {
    vi.mocked(useAuthStore).mockReturnValue({ isManager: false } as ReturnType<typeof useAuthStore>)
    const wrapper = mount(DashboardRouter, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          ManagerDashboard: { template: '<div class="manager-dashboard"/>' },
          UserDashboard: { template: '<div class="user-dashboard"/>' },
        },
      },
    })
    expect(wrapper.find('.user-dashboard').exists()).toBe(true)
    expect(wrapper.find('.manager-dashboard').exists()).toBe(false)
  })
})
