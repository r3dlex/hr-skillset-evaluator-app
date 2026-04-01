import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import SettingsView from '../SettingsView.vue'

vi.mock('@/stores/skills', () => ({
  useSkillsStore: vi.fn(),
}))

vi.mock('@/stores/theme', () => ({
  useThemeStore: vi.fn(),
}))

import { useSkillsStore } from '@/stores/skills'
import { useThemeStore } from '@/stores/theme'

const mockSkillset = {
  id: 1,
  name: 'Frontend',
  description: 'Frontend skills',
  skill_groups: [],
}

const mockSkillsStore = {
  skillsets: [mockSkillset],
  fetchSkillsets: vi.fn(),
  createSkillset: vi.fn(),
  updateSkillset: vi.fn(),
  deleteSkillset: vi.fn(),
}

const mockThemeStore = {
  themeName: 'default',
  colorMode: 'system',
  setTheme: vi.fn(),
  setColorMode: vi.fn(),
}

const router = createRouter({
  history: createWebHistory(),
  routes: [{ path: '/', component: { template: '<div/>' } }],
})

describe('SettingsView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useSkillsStore).mockReturnValue(mockSkillsStore as unknown as ReturnType<typeof useSkillsStore>)
    vi.mocked(useThemeStore).mockReturnValue(mockThemeStore as unknown as ReturnType<typeof useThemeStore>)
    mockSkillsStore.skillsets = [mockSkillset]
    mockSkillsStore.fetchSkillsets.mockResolvedValue(undefined)
    mockSkillsStore.createSkillset.mockResolvedValue(undefined)
    mockSkillsStore.updateSkillset.mockResolvedValue(undefined)
    mockSkillsStore.deleteSkillset.mockResolvedValue(undefined)
  })

  function mountComponent() {
    return mount(SettingsView, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          AppLayout: { template: '<div><slot /></div>' },
          XlsxUpload: { template: '<div class="xlsx-upload"/>' },
        },
      },
    })
  }

  it('renders settings header', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Settings')
  })

  it('calls fetchSkillsets on mount', async () => {
    mountComponent()
    await flushPromises()
    expect(mockSkillsStore.fetchSkillsets).toHaveBeenCalled()
  })

  it('shows New Skillset button', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('New Skillset')
  })

  it('toggles create form on button click', async () => {
    const wrapper = mountComponent()
    const btn = wrapper.find('button.btn-primary')
    await btn.trigger('click')
    expect(wrapper.text()).toContain('Cancel')
    await btn.trigger('click')
    expect(wrapper.text()).toContain('New Skillset')
  })

  it('shows skillsets list', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Frontend')
  })

  it('shows Appearance section', () => {
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('Appearance')
  })
})
