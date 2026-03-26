import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import GapAnalysis from '../GapAnalysis.vue'
import type { GapAnalysisItem } from '@/types'

const sampleItems: GapAnalysisItem[] = [
  { name: 'JavaScript', manager_score: 4, self_score: 3, gap: 1 },
  { name: 'Python', manager_score: 2, self_score: 4, gap: -2 },
  { name: 'Go', manager_score: 3, self_score: 3, gap: 0 },
  { name: 'Rust', manager_score: 5, self_score: 2, gap: 3 },
]

describe('GapAnalysis', () => {
  it('renders correct number of skill rows', () => {
    const wrapper = mount(GapAnalysis, {
      props: { items: sampleItems },
    })
    const rows = wrapper.findAll('.border.border-gray-100')
    expect(rows.length).toBe(sampleItems.length)
  })

  it('displays skill names', () => {
    const wrapper = mount(GapAnalysis, {
      props: { items: sampleItems },
    })
    const text = wrapper.text()
    for (const item of sampleItems) {
      expect(text).toContain(item.name)
    }
  })

  it('shows manager and self score values', () => {
    const wrapper = mount(GapAnalysis, {
      props: { items: sampleItems },
    })
    const text = wrapper.text()
    // Scores are displayed with .toFixed(1)
    expect(text).toContain('4.0') // JavaScript manager_score
    expect(text).toContain('3.0') // JavaScript self_score / Go scores
    expect(text).toContain('2.0') // Python manager_score / Rust self_score
    expect(text).toContain('5.0') // Rust manager_score
  })

  it('calculates and displays gap values', () => {
    const wrapper = mount(GapAnalysis, {
      props: { items: sampleItems },
    })
    const text = wrapper.text()
    expect(text).toContain('+1.0')
    expect(text).toContain('-2.0')
    expect(text).toContain('0.0')
    expect(text).toContain('+3.0')
  })

  it('sorts by absolute gap (largest first)', () => {
    const wrapper = mount(GapAnalysis, {
      props: { items: sampleItems },
    })
    // Sorted order by absolute gap: Rust(3), Python(2), JavaScript(1), Go(0)
    const skillNames = wrapper.findAll('.text-sm.font-medium.text-gray-900')
    const names = skillNames.map((el) => el.text())
    expect(names[0]).toBe('Rust')
    expect(names[1]).toBe('Python')
    expect(names[2]).toBe('JavaScript')
    expect(names[3]).toBe('Go')
  })

  it('handles empty items gracefully', () => {
    const wrapper = mount(GapAnalysis, {
      props: { items: [] },
    })
    expect(wrapper.text()).toContain('No gap analysis data available')
    expect(wrapper.findAll('.border.border-gray-100').length).toBe(0)
  })
})
