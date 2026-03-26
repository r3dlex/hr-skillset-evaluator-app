import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import TeamLegend from '../TeamLegend.vue'
import type { RadarSeries } from '@/types'

const sampleSeries: RadarSeries[] = [
  { user_id: 1, name: 'Alice', color: '#3b82f6', values: [4, 3, 5] },
  { user_id: 2, name: 'Bob', color: '#ef4444', values: [3, 2, 4] },
  { user_id: 3, name: 'Charlie', color: '#10b981', values: [5, 5, 5] },
]

describe('TeamLegend', () => {
  it('renders one item per series', () => {
    const wrapper = mount(TeamLegend, {
      props: { series: sampleSeries },
    })
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBe(3)
  })

  it('shows color swatches matching series colors', () => {
    const wrapper = mount(TeamLegend, {
      props: { series: sampleSeries },
    })
    const swatches = wrapper.findAll('.w-3.h-3.rounded-full')
    expect(swatches.length).toBe(3)
    expect(swatches[0].attributes('style')).toContain('#3b82f6')
    expect(swatches[1].attributes('style')).toContain('#ef4444')
    expect(swatches[2].attributes('style')).toContain('#10b981')
  })

  it('toggles opacity on click (toggle visibility)', async () => {
    const wrapper = mount(TeamLegend, {
      props: { series: sampleSeries },
    })
    const buttons = wrapper.findAll('button')

    // Initially no items have opacity-40 class
    expect(buttons[0].classes()).not.toContain('opacity-40')

    // Click first button to hide
    await buttons[0].trigger('click')

    // After click, the first button should have opacity-40
    const updatedButtons = wrapper.findAll('button')
    expect(updatedButtons[0].classes()).toContain('opacity-40')

    // Click again to show
    await updatedButtons[0].trigger('click')
    const finalButtons = wrapper.findAll('button')
    expect(finalButtons[0].classes()).not.toContain('opacity-40')
  })

  it('shows user names', () => {
    const wrapper = mount(TeamLegend, {
      props: { series: sampleSeries },
    })
    const text = wrapper.text()
    expect(text).toContain('Alice')
    expect(text).toContain('Bob')
    expect(text).toContain('Charlie')
  })

  it('shows empty message when no series provided', () => {
    const wrapper = mount(TeamLegend, {
      props: { series: [] },
    })
    expect(wrapper.text()).toContain('No members selected')
  })
})
