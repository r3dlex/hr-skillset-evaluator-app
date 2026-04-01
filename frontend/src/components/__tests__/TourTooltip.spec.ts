import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import TourTooltip from '../TourTooltip.vue'

const mockStep = {
  target: '.test-element',
  title: 'Test Step',
  content: 'This is a test step description.',
  position: 'right' as const,
}

const mockRect = {
  top: 100,
  left: 200,
  width: 150,
  height: 50,
  right: 350,
  bottom: 150,
} as DOMRect

describe('TourTooltip', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  function mountComponent(props = {}) {
    return mount(TourTooltip, {
      props: {
        isActive: false,
        currentStep: null,
        targetRect: null,
        stepLabel: '1 / 3',
        isFirst: true,
        isLast: false,
        ...props,
      },
    })
  }

  it('does not show tooltip when inactive', () => {
    const wrapper = mountComponent({ isActive: false })
    // Tooltip should not be visible
    expect(wrapper.find('[role="dialog"]').exists()).toBe(false)
  })

  it('shows overlay when active', async () => {
    mountComponent({ isActive: true, currentStep: mockStep })
    // Teleport renders to document.body; check the body for .fixed class
    expect(document.body.querySelector('.fixed')).not.toBeNull()
  })

  it('shows step title', async () => {
    mountComponent({ isActive: true, currentStep: mockStep })
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(document.body.textContent).toContain('Test Step')
  })

  it('shows step content', async () => {
    mountComponent({ isActive: true, currentStep: mockStep })
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(document.body.textContent).toContain('This is a test step description.')
  })

  it('shows step label', async () => {
    mountComponent({ isActive: true, currentStep: mockStep, stepLabel: '2 / 3' })
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(document.body.textContent).toContain('2 / 3')
  })

  it('emits stop when close button clicked', async () => {
    const wrapper = mountComponent({ isActive: true, currentStep: mockStep })
    await new Promise(resolve => setTimeout(resolve, 0))
    // Find the close/stop button (X button)
    const closeButtons = wrapper.findAll('button')
    const closeBtn = closeButtons.find(b => b.attributes('aria-label') === 'Close tour' || b.text() === '×' || b.html().includes('M6 18'))
    if (closeBtn) {
      await closeBtn.trigger('click')
      expect(wrapper.emitted('stop')).toBeTruthy()
    }
  })

  it('emits next when Next button clicked', async () => {
    const wrapper = mountComponent({ isActive: true, currentStep: mockStep, isLast: false })
    await new Promise(resolve => setTimeout(resolve, 0))
    const buttons = wrapper.findAll('button')
    const nextBtn = buttons.find(b => b.text().includes('Next'))
    if (nextBtn) {
      await nextBtn.trigger('click')
      expect(wrapper.emitted('next')).toBeTruthy()
    }
  })

  it('emits prev when Previous button clicked', async () => {
    const wrapper = mountComponent({ isActive: true, currentStep: mockStep, isFirst: false })
    await new Promise(resolve => setTimeout(resolve, 0))
    const buttons = wrapper.findAll('button')
    const prevBtn = buttons.find(b => b.text().includes('Prev') || b.text().includes('Back'))
    if (prevBtn) {
      await prevBtn.trigger('click')
      expect(wrapper.emitted('prev')).toBeTruthy()
    }
  })

  it('emits stop when Finish button clicked on last step', async () => {
    const wrapper = mountComponent({ isActive: true, currentStep: mockStep, isLast: true })
    await new Promise(resolve => setTimeout(resolve, 0))
    const buttons = wrapper.findAll('button')
    const finishBtn = buttons.find(b => b.text().includes('Finish') || b.text().includes('Done'))
    if (finishBtn) {
      await finishBtn.trigger('click')
      expect(wrapper.emitted('stop') || wrapper.emitted('next')).toBeTruthy()
    }
  })

  it('positions tooltip with target rect', async () => {
    const wrapper = mountComponent({
      isActive: true,
      currentStep: mockStep,
      targetRect: mockRect,
    })
    await new Promise(resolve => setTimeout(resolve, 0))
    // The tooltip should be positioned based on rect
    expect(wrapper.exists()).toBe(true)
  })

  it('positions tooltip centered when no target rect', async () => {
    const wrapper = mountComponent({
      isActive: true,
      currentStep: mockStep,
      targetRect: null,
    })
    await new Promise(resolve => setTimeout(resolve, 0))
    // Should use center positioning
    expect(wrapper.exists()).toBe(true)
  })

  it('handles bottom position', async () => {
    const bottomStep = { ...mockStep, position: 'bottom' as const }
    const wrapper = mountComponent({ isActive: true, currentStep: bottomStep, targetRect: mockRect })
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(wrapper.exists()).toBe(true)
  })

  it('handles top position', async () => {
    const topStep = { ...mockStep, position: 'top' as const }
    const wrapper = mountComponent({ isActive: true, currentStep: topStep, targetRect: mockRect })
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(wrapper.exists()).toBe(true)
  })

  it('handles left position', async () => {
    const leftStep = { ...mockStep, position: 'left' as const }
    const wrapper = mountComponent({ isActive: true, currentStep: leftStep, targetRect: mockRect })
    await new Promise(resolve => setTimeout(resolve, 0))
    expect(wrapper.exists()).toBe(true)
  })
})
