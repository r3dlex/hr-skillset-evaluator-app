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
    const rows = wrapper.findAll('.rounded-lg.p-4')
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
    expect(text).toContain('4.0')
    expect(text).toContain('3.0')
    expect(text).toContain('2.0')
    expect(text).toContain('5.0')
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
    const skillNames = wrapper.findAll('.text-sm.font-medium')
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
    expect(wrapper.findAll('.rounded-lg.p-4').length).toBe(0)
  })

  it('sorts by priority first (critical > high > medium > low)', () => {
    const items: GapAnalysisItem[] = [
      { name: 'Low Skill', priority: 'low', manager_score: 1, self_score: 0, gap: 1 },
      { name: 'Critical Skill', priority: 'critical', manager_score: 1, self_score: 0, gap: 1 },
      { name: 'High Skill', priority: 'high', manager_score: 1, self_score: 0, gap: 1 },
      { name: 'Medium Skill', priority: 'medium', manager_score: 1, self_score: 0, gap: 1 },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    const skillNames = wrapper.findAll('.text-sm.font-medium')
    const names = skillNames.map((el) => el.text())
    expect(names[0]).toBe('Critical Skill')
    expect(names[1]).toBe('High Skill')
    expect(names[2]).toBe('Medium Skill')
    expect(names[3]).toBe('Low Skill')
  })

  it('shows priority badges for items with priority', () => {
    const items: GapAnalysisItem[] = [
      { name: 'A', priority: 'critical', manager_score: 3, self_score: 1, gap: 2 },
      { name: 'B', priority: 'high', manager_score: 3, self_score: 2, gap: 1 },
      { name: 'C', priority: 'medium', manager_score: 2, self_score: 2, gap: 0 },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    const text = wrapper.text()
    expect(text).toContain('critical')
    expect(text).toContain('high')
    expect(text).toContain('medium')
  })

  it('renders team_avg and role_avg score bars', () => {
    const items: GapAnalysisItem[] = [
      {
        name: 'TypeScript',
        manager_score: 4,
        self_score: 3,
        team_avg: 3.5,
        role_avg: 3.8,
        gap: 1,
      },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    const text = wrapper.text()
    expect(text).toContain('Team Avg')
    expect(text).toContain('Role Avg')
    expect(text).toContain('3.5')
    expect(text).toContain('3.8')
  })

  it('shows "No gap data" when gap is null', () => {
    const items: GapAnalysisItem[] = [
      { name: 'NoGap Skill', manager_score: null, self_score: null, gap: null },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    expect(wrapper.text()).toContain('No gap data')
  })

  it('shows "No assessment data available" when all scores are null', () => {
    const items: GapAnalysisItem[] = [
      { name: 'Empty Skill', manager_score: null, self_score: null, team_avg: null, role_avg: null, gap: null },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    expect(wrapper.text()).toContain('No assessment data available')
  })

  it('applies red color class for large gaps (>= 2)', () => {
    const items: GapAnalysisItem[] = [
      { name: 'BigGap', manager_score: 5, self_score: 1, gap: 4 },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    // The gap badge should have red styling
    const gapBadge = wrapper.find('.rounded-full')
    expect(gapBadge.exists()).toBe(true)
    expect(gapBadge.classes().some(c => c.includes('red'))).toBe(true)
  })

  it('applies orange color class for medium gaps (1 <= gap < 2)', () => {
    const items: GapAnalysisItem[] = [
      { name: 'MedGap', manager_score: 3, self_score: 2, gap: 1 },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    const gapBadge = wrapper.find('.rounded-full')
    expect(gapBadge.exists()).toBe(true)
    expect(gapBadge.classes().some(c => c.includes('orange'))).toBe(true)
  })

  it('applies green color class for small gaps (< 1)', () => {
    const items: GapAnalysisItem[] = [
      { name: 'SmallGap', manager_score: 3, self_score: 3, gap: 0 },
    ]
    const wrapper = mount(GapAnalysis, { props: { items } })
    const gapBadge = wrapper.find('.rounded-full')
    expect(gapBadge.exists()).toBe(true)
    expect(gapBadge.classes().some(c => c.includes('green'))).toBe(true)
  })
})
