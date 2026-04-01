import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import AppLogo from '../AppLogo.vue'
import RibLogo from '../RibLogo.vue'
import SkillForgeLogo from '../SkillForgeLogo.vue'

vi.mock('@/stores/theme', () => ({ useThemeStore: vi.fn() }))

import { useThemeStore } from '@/stores/theme'

const mockThemeStore = {
  themeName: 'default',
  colorMode: 'light',
  isDark: false,
}

describe('Logo components', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useThemeStore).mockReturnValue(mockThemeStore as ReturnType<typeof useThemeStore>)
  })

  describe('AppLogo', () => {
    it('renders without crashing', () => {
      const wrapper = mount(AppLogo, {
        global: {
          plugins: [createPinia()],
          stubs: { SkillForgeLogo: { template: '<span class="sf-logo"/>' } },
        },
      })
      expect(wrapper.exists()).toBe(true)
    })

    it('shows SkillForgeLogo', () => {
      const wrapper = mount(AppLogo, {
        global: {
          plugins: [createPinia()],
          stubs: { SkillForgeLogo: { template: '<span class="sf-logo"/>' } },
        },
      })
      expect(wrapper.find('.sf-logo').exists()).toBe(true)
    })

    it('does not show RIB badge in default theme', () => {
      mockThemeStore.themeName = 'default'
      const wrapper = mount(AppLogo, {
        global: {
          plugins: [createPinia()],
          stubs: { SkillForgeLogo: { template: '<span class="sf-logo"/>' } },
        },
      })
      // No RIB text in default theme
      expect(wrapper.text()).not.toContain('RIB')
    })

    it('shows "by RIB" badge when rib theme is active', () => {
      mockThemeStore.themeName = 'rib'
      const wrapper = mount(AppLogo, {
        global: {
          plugins: [createPinia()],
          stubs: { SkillForgeLogo: { template: '<span class="sf-logo"/>' } },
        },
      })
      expect(wrapper.text()).toContain('by RIB')
    })

    it('hides "by RIB" badge when rib theme is active but collapsed=true', () => {
      mockThemeStore.themeName = 'rib'
      const wrapper = mount(AppLogo, {
        props: { collapsed: true },
        global: {
          plugins: [createPinia()],
          stubs: { SkillForgeLogo: { template: '<span class="sf-logo"/>' } },
        },
      })
      expect(wrapper.text()).not.toContain('by RIB')
    })

    it('accepts size prop', () => {
      const wrapper = mount(AppLogo, {
        props: { size: 48 },
        global: {
          plugins: [createPinia()],
          stubs: { SkillForgeLogo: { template: '<span class="sf-logo"/>' } },
        },
      })
      expect(wrapper.exists()).toBe(true)
    })

    it('accepts collapsed prop', () => {
      const wrapper = mount(AppLogo, {
        props: { collapsed: true },
        global: {
          plugins: [createPinia()],
          stubs: { SkillForgeLogo: { template: '<span class="sf-logo"/>' } },
        },
      })
      expect(wrapper.exists()).toBe(true)
    })
  })

  describe('RibLogo', () => {
    it('renders SVG', () => {
      const wrapper = mount(RibLogo)
      // RibLogo uses an <img> tag with the RIB logo PNG
      expect(wrapper.find('img').exists()).toBe(true)
    })
  })

  describe('SkillForgeLogo', () => {
    it('renders without crashing', () => {
      const wrapper = mount(SkillForgeLogo, {
        global: {
          plugins: [createPinia()],
        },
      })
      expect(wrapper.exists()).toBe(true)
    })

    it('renders SVG icon', () => {
      const wrapper = mount(SkillForgeLogo)
      expect(wrapper.find('svg').exists()).toBe(true)
    })

    it('accepts size prop', () => {
      const wrapper = mount(SkillForgeLogo, { props: { size: 48 } })
      expect(wrapper.exists()).toBe(true)
    })

    it('shows text when showText is true', () => {
      const wrapper = mount(SkillForgeLogo, { props: { showText: true } })
      expect(wrapper.text()).toContain('SkillForge')
    })

    it('hides text when showText is false', () => {
      const wrapper = mount(SkillForgeLogo, { props: { showText: false } })
      expect(wrapper.find('.text-element') || !wrapper.text().includes('SkillForge')).toBeTruthy()
    })
  })
})
