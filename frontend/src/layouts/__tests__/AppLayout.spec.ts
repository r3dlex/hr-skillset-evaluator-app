import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import AppLayout from '../AppLayout.vue'

vi.mock('@/stores/theme', () => ({
  useThemeStore: vi.fn(),
}))

vi.mock('@/stores/chat', () => ({
  useChatStore: vi.fn(),
}))

vi.mock('@/composables/useTour', () => ({
  useTour: vi.fn(),
}))

import { useThemeStore } from '@/stores/theme'
import { useChatStore } from '@/stores/chat'
import { useTour } from '@/composables/useTour'
import { ref } from 'vue'

const mockThemeStore = {
  sidebarCollapsed: false,
}

const mockChatStore = {
  isPanelOpen: false,
  isStreaming: false,
  togglePanel: vi.fn(),
}

const mockTour = {
  isActive: ref(false),
  currentStep: ref(null),
  targetRect: ref(null),
  stepLabel: ref('1 / 1'),
  isFirst: ref(true),
  isLast: ref(true),
  start: vi.fn(),
  next: vi.fn(),
  prev: vi.fn(),
  stop: vi.fn(),
}

describe('AppLayout', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useThemeStore).mockReturnValue(mockThemeStore as ReturnType<typeof useThemeStore>)
    vi.mocked(useChatStore).mockReturnValue(mockChatStore as unknown as ReturnType<typeof useChatStore>)
    vi.mocked(useTour).mockReturnValue(mockTour as unknown as ReturnType<typeof useTour>)
  })

  function mountComponent() {
    return mount(AppLayout, {
      global: {
        plugins: [createPinia()],
        stubs: {
          Sidebar: { template: '<div class="sidebar"/>' },
          TourTooltip: { template: '<div class="tour-tooltip"/>' },
          ChatPanel: { template: '<div class="chat-panel"/>' },
        },
      },
      slots: {
        default: '<div class="slot-content">Content</div>',
      },
    })
  }

  it('renders slot content', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('.slot-content').exists()).toBe(true)
    expect(wrapper.text()).toContain('Content')
  })

  it('renders sidebar', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('.sidebar').exists()).toBe(true)
  })

  it('renders chat panel', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('.chat-panel').exists()).toBe(true)
  })

  it('shows chat FAB when panel is closed', () => {
    mockChatStore.isPanelOpen = false
    const wrapper = mountComponent()
    expect(wrapper.find('[data-tour="chat-fab"]').exists()).toBe(true)
  })

  it('hides chat FAB when panel is open', () => {
    mockChatStore.isPanelOpen = true
    const wrapper = mountComponent()
    expect(wrapper.find('[data-tour="chat-fab"]').exists()).toBe(false)
  })

  it('calls togglePanel when FAB is clicked', async () => {
    mockChatStore.isPanelOpen = false
    const wrapper = mountComponent()
    await wrapper.find('[data-tour="chat-fab"]').trigger('click')
    expect(mockChatStore.togglePanel).toHaveBeenCalled()
  })

  it('shows streaming indicator when streaming', () => {
    mockChatStore.isPanelOpen = false
    mockChatStore.isStreaming = true
    const wrapper = mountComponent()
    expect(wrapper.find('.animate-pulse').exists()).toBe(true)
  })

  it('hides streaming indicator when not streaming', () => {
    mockChatStore.isPanelOpen = false
    mockChatStore.isStreaming = false
    const wrapper = mountComponent()
    expect(wrapper.find('.animate-pulse').exists()).toBe(false)
  })
})
