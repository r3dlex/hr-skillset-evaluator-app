import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SkillsetTabs from '../SkillsetTabs.vue'
import type { Skillset } from '@/types'

const sampleSkillsets: Skillset[] = [
  { id: 1, name: 'Frontend', description: '', position: 0, skill_count: 10 },
  { id: 2, name: 'Backend', description: '', position: 1, skill_count: 8 },
  { id: 3, name: 'DevOps', description: '', position: 2, skill_count: 5 },
]

describe('SkillsetTabs', () => {
  it('renders correct number of tabs', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: 1 },
    })
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBe(sampleSkillsets.length)
  })

  it('highlights active tab with primary color', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: 2 },
    })
    const buttons = wrapper.findAll('button')
    // Active tab uses inline style with primary color
    const activeStyle = buttons[1].attributes('style') || ''
    expect(activeStyle).toContain('var(--color-primary)')
    // Non-active tabs use surface color
    const inactiveStyle = buttons[0].attributes('style') || ''
    expect(inactiveStyle).toContain('var(--color-surface)')
  })

  it('emits select event on tab click', async () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: 1 },
    })
    const buttons = wrapper.findAll('button')
    await buttons[2].trigger('click')
    expect(wrapper.emitted('select')).toBeTruthy()
    expect(wrapper.emitted('select')![0]).toEqual([3])
  })

  it('displays skillset names and counts', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: 1 },
    })
    expect(wrapper.text()).toContain('Frontend')
    expect(wrapper.text()).toContain('(10)')
    expect(wrapper.text()).toContain('Backend')
    expect(wrapper.text()).toContain('(8)')
  })

  it('shows message when no skillsets', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: [], activeId: null },
    })
    expect(wrapper.text()).toContain('No skillsets available')
  })
})
