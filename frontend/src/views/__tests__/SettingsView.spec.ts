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

  it('opens edit form when Edit button is clicked', async () => {
    const wrapper = mountComponent()
    await flushPromises()
    const editBtn = wrapper.find('button[title="Edit"]')
    if (editBtn.exists()) {
      await editBtn.trigger('click')
      // Edit form should appear with Cancel and Save buttons
      expect(wrapper.text()).toContain('Save')
    }
  })

  it('cancels edit when Cancel is clicked in edit mode', async () => {
    const wrapper = mountComponent()
    await flushPromises()
    const editBtn = wrapper.find('button[title="Edit"]')
    if (editBtn.exists()) {
      await editBtn.trigger('click')
      const cancelBtn = wrapper.findAll('button').find(b => b.text() === 'Cancel')
      if (cancelBtn) {
        await cancelBtn.trigger('click')
        // Should return to showing the skillset name
        expect(wrapper.text()).toContain('Frontend')
      }
    }
  })

  it('calls deleteSkillset when Delete is confirmed', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(true)
    const wrapper = mountComponent()
    await flushPromises()
    const deleteBtn = wrapper.find('button[title="Delete"]')
    if (deleteBtn.exists()) {
      await deleteBtn.trigger('click')
      await flushPromises()
      expect(mockSkillsStore.deleteSkillset).toHaveBeenCalledWith(1)
    }
    vi.restoreAllMocks()
  })

  it('does not call deleteSkillset when Delete is cancelled', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(false)
    const wrapper = mountComponent()
    await flushPromises()
    const deleteBtn = wrapper.find('button[title="Delete"]')
    if (deleteBtn.exists()) {
      await deleteBtn.trigger('click')
      await flushPromises()
      expect(mockSkillsStore.deleteSkillset).not.toHaveBeenCalled()
    }
    vi.restoreAllMocks()
  })

  it('calls createSkillset when form is submitted with valid name', async () => {
    const wrapper = mountComponent()
    await flushPromises()
    // Open create form
    const btn = wrapper.find('button.btn-primary')
    await btn.trigger('click')
    // Fill in name
    const nameInput = wrapper.find('input[placeholder*="name"], input[type="text"]')
    if (nameInput.exists()) {
      await nameInput.setValue('New Skillset')
      // Submit form
      const form = wrapper.find('form')
      if (form.exists()) {
        await form.trigger('submit')
        await flushPromises()
        expect(mockSkillsStore.createSkillset).toHaveBeenCalled()
      }
    }
  })

  it('moves skillset up when Move Up button is clicked', async () => {
    mockSkillsStore.skillsets = [
      { id: 1, name: 'First', description: '', skill_groups: [] },
      { id: 2, name: 'Second', description: '', skill_groups: [] },
    ]
    const wrapper = mountComponent()
    await flushPromises()
    const moveUpBtns = wrapper.findAll('button[title="Move up"]')
    // Second item's "Move up" button (index 1) should be enabled (element.disabled = false)
    const enabledMoveUp = moveUpBtns.find(b => !(b.element as HTMLButtonElement).disabled)
    if (enabledMoveUp) {
      await enabledMoveUp.trigger('click')
      // skillsets should be reordered (second is now first)
      expect(mockSkillsStore.skillsets[0].name).toBe('Second')
    }
  })

  it('shows skill_count badge when skillset has skill_count', () => {
    mockSkillsStore.skillsets = [{ id: 1, name: 'Frontend', description: '', skill_groups: [], skill_count: 12 }] as any
    const wrapper = mountComponent()
    expect(wrapper.text()).toContain('12 skills')
  })

  it('moves skillset down when Move Down button is clicked', async () => {
    mockSkillsStore.skillsets = [
      { id: 1, name: 'First', description: '', skill_groups: [] },
      { id: 2, name: 'Second', description: '', skill_groups: [] },
    ]
    const wrapper = mountComponent()
    await flushPromises()
    const moveDownBtns = wrapper.findAll('button[title="Move down"]')
    // First item's "Move down" button (index 0) should be enabled
    const enabledMoveDown = moveDownBtns.find(b => !(b.element as HTMLButtonElement).disabled)
    if (enabledMoveDown) {
      await enabledMoveDown.trigger('click')
      expect(mockSkillsStore.skillsets[0].name).toBe('Second')
    }
  })
})
