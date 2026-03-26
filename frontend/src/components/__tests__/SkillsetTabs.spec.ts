import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import SkillsetTabs from '../SkillsetTabs.vue'
import type { Skillset } from '@/types'

const sampleSkillsets: Skillset[] = [
  { id: 1, name: 'Frontend', description: 'Frontend skills', position: 1, skill_count: 10 },
  { id: 2, name: 'Backend', description: 'Backend skills', position: 2, skill_count: 8 },
  { id: 3, name: 'DevOps', description: 'DevOps skills', position: 3 },
]

describe('SkillsetTabs', () => {
  it('renders one tab per skillset', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: null },
    })
    const buttons = wrapper.findAll('button')
    expect(buttons.length).toBe(3)
  })

  it('highlights active tab', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: 2 },
    })
    const buttons = wrapper.findAll('button')
    // Active tab (Backend, id=2) should have bg-primary class
    expect(buttons[1].classes()).toContain('bg-primary')
    expect(buttons[1].classes()).toContain('text-white')
    // Non-active tabs should have bg-white class
    expect(buttons[0].classes()).toContain('bg-white')
    expect(buttons[2].classes()).toContain('bg-white')
  })

  it('emits select event on click', async () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: null },
    })
    const buttons = wrapper.findAll('button')
    await buttons[2].trigger('click')

    const emitted = wrapper.emitted('select')
    expect(emitted).toBeTruthy()
    expect(emitted![0]).toEqual([3])
  })

  it('displays skillset names and skill counts', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: sampleSkillsets, activeId: null },
    })
    const text = wrapper.text()
    expect(text).toContain('Frontend')
    expect(text).toContain('(10)')
    expect(text).toContain('Backend')
    expect(text).toContain('(8)')
    expect(text).toContain('DevOps')
  })

  it('shows empty message when no skillsets provided', () => {
    const wrapper = mount(SkillsetTabs, {
      props: { skillsets: [], activeId: null },
    })
    expect(wrapper.text()).toContain('No skillsets available')
  })
})
