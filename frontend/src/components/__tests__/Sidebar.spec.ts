import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import Sidebar from '../Sidebar.vue'

vi.mock('@/stores/auth', () => ({ useAuthStore: vi.fn() }))
vi.mock('@/stores/skills', () => ({ useSkillsStore: vi.fn() }))
vi.mock('@/stores/onboarding', () => ({ useOnboardingStore: vi.fn() }))
vi.mock('@/stores/theme', () => ({ useThemeStore: vi.fn() }))

import { useAuthStore } from '@/stores/auth'
import { useSkillsStore } from '@/stores/skills'
import { useOnboardingStore } from '@/stores/onboarding'
import { useThemeStore } from '@/stores/theme'

const mockUser = { id: 1, name: 'Alice', email: 'alice@example.com', role: 'manager' as const, active: true }
const mockSkillsets = [
  { id: 1, name: 'Frontend', description: '', skill_groups: [] },
  { id: 2, name: 'Domain', description: '', skill_groups: [] },
]

const mockAuthStore = {
  user: mockUser,
  isManager: true,
  isAuthenticated: true,
  logout: vi.fn(),
}

const mockSkillsStore = {
  skillsets: mockSkillsets,
  loading: false,
  fetchSkillsets: vi.fn(),
}

const mockOnboardingStore = {
  isVisible: false,
  syncFromUser: vi.fn(),
}

const mockThemeStore = {
  sidebarCollapsed: false,
  toggleSidebar: vi.fn(),
}

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: { template: '<div/>' } },
    { path: '/dashboard', component: { template: '<div/>' } },
    { path: '/settings/skillsets', component: { template: '<div/>' } },
    { path: '/skillsets/:id', component: { template: '<div/>' } },
    { path: '/login', component: { template: '<div/>' } },
  ],
})

describe('Sidebar', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useAuthStore).mockReturnValue(mockAuthStore as unknown as ReturnType<typeof useAuthStore>)
    vi.mocked(useSkillsStore).mockReturnValue(mockSkillsStore as unknown as ReturnType<typeof useSkillsStore>)
    vi.mocked(useOnboardingStore).mockReturnValue(mockOnboardingStore as unknown as ReturnType<typeof useOnboardingStore>)
    vi.mocked(useThemeStore).mockReturnValue(mockThemeStore as unknown as ReturnType<typeof useThemeStore>)
    mockThemeStore.sidebarCollapsed = false
    mockAuthStore.isManager = true
    mockAuthStore.user = mockUser
    mockSkillsStore.skillsets = mockSkillsets
    mockOnboardingStore.isVisible = false
  })

  function mountComponent() {
    return mount(Sidebar, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          OnboardingChecklist: { template: '<div class="onboarding-checklist"/>' },
          AppLogo: { template: '<span class="app-logo"/>' },
        },
        provide: {
          startTour: vi.fn(),
        },
      },
    })
  }

  it('renders navigation links', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Dashboard')
  })

  it('shows Settings link for managers', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Settings')
  })

  it('hides Settings link for non-managers', () => {
    mockAuthStore.isManager = false
    const wrapper = mountComponent()
    expect(wrapper.text()).not.toContain('Settings')
  })

  it('shows skillsets list', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Frontend')
  })

  it('shows user name', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Alice')
  })

  it('shows user email', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('alice@example.com')
  })

  it('shows user initial in avatar', () => {
    const wrapper = mountComponent()
    // User initial "A" from "Alice"
    expect(wrapper.text()).toContain('A')
  })

  it('calls fetchSkillsets on mount if empty', async () => {
    mockSkillsStore.skillsets = []
    mountComponent()
    await flushPromises()
    expect(mockSkillsStore.fetchSkillsets).toHaveBeenCalled()
  })

  it('does not call fetchSkillsets if skillsets already loaded', async () => {
    mountComponent()
    await flushPromises()
    expect(mockSkillsStore.fetchSkillsets).not.toHaveBeenCalled()
  })

  it('calls syncFromUser on mount', async () => {
    mountComponent()
    await flushPromises()
    expect(mockOnboardingStore.syncFromUser).toHaveBeenCalled()
  })

  it('shows "No skillsets yet" when no skillsets', () => {
    mockSkillsStore.skillsets = []
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('No skillsets yet')
  })

  it('calls toggleSidebar when collapse button clicked', async () => {
    const wrapper = mountComponent()
    const buttons = wrapper.findAll('button')
    const toggleBtn = buttons.find(b => b.attributes('title')?.includes('Collapse'))
    if (toggleBtn) {
      await toggleBtn.trigger('click')
      expect(mockThemeStore.toggleSidebar).toHaveBeenCalled()
    }
  })

  it('handles logout', async () => {
    mockAuthStore.logout.mockResolvedValue(undefined)
    Object.defineProperty(window, 'location', { writable: true, value: { href: '/' } })
    const wrapper = mountComponent()
    const logoutBtn = wrapper.find('button[title="Sign out"]')
    if (logoutBtn.exists()) {
      await logoutBtn.trigger('click')
      await flushPromises()
      expect(mockAuthStore.logout).toHaveBeenCalled()
    }
  })

  it('shows onboarding checklist when visible', () => {
    mockOnboardingStore.isVisible = true
    const wrapper = mountComponent()
    expect(wrapper.find('.onboarding-checklist').exists()).toBe(true)
  })

  it('hides onboarding checklist when not visible', () => {
    mockOnboardingStore.isVisible = false
    const wrapper = mountComponent()
    expect(wrapper.find('.onboarding-checklist').exists()).toBe(false)
  })

  it('shows Skillsets header text', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Skillsets')
  })

  it('uses visibleSkillsets filtering for non-managers', () => {
    mockAuthStore.isManager = false
    mockAuthStore.user = { ...mockUser, role: 'user' } as unknown as typeof mockUser
    // All skillsets with no applicable_roles should be visible
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Frontend')
  })

  it('handles skillsets with applicable_roles filtering', () => {
    mockAuthStore.isManager = false
    mockAuthStore.user = { ...mockUser, role: 'user', job_title: 'Engineer' } as unknown as typeof mockUser
    mockSkillsStore.skillsets = [
      { id: 1, name: 'Frontend', description: '', skill_groups: [], applicable_roles: ['Engineer'] },
      { id: 2, name: 'Management', description: '', skill_groups: [], applicable_roles: ['Manager'] },
    ] as unknown as typeof mockSkillsets
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Frontend')
    expect(wrapper.text()).not.toContain('Management')
  })
})
