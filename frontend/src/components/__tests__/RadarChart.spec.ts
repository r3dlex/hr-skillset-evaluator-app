import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import RadarChart from '../RadarChart.vue'
import type { RadarData } from '@/types'

function makeRadarData(axisCount = 4, seriesCount = 2): RadarData {
  const axes = Array.from({ length: axisCount }, (_, i) => `Skill ${i + 1}`)
  const colors = ['#3b82f6', '#ef4444', '#10b981', '#f59e0b']
  const series = Array.from({ length: seriesCount }, (_, i) => ({
    user_id: i + 1,
    name: `User ${i + 1}`,
    color: colors[i % colors.length],
    values: Array.from({ length: axisCount }, () => Math.round(Math.random() * 5)),
  }))
  return { axes, series }
}

describe('RadarChart', () => {
  it('renders an SVG element', () => {
    const wrapper = mount(RadarChart, {
      props: { radarData: makeRadarData() },
    })
    expect(wrapper.find('svg').exists()).toBe(true)
  })

  it('renders correct number of axis lines based on radarData.axes', () => {
    const radarData = makeRadarData(6, 1)
    const wrapper = mount(RadarChart, {
      props: { radarData },
    })
    const lines = wrapper.findAll('line')
    expect(lines.length).toBe(6)
  })

  it('renders correct number of data polygons based on series count', () => {
    const radarData = makeRadarData(5, 3)
    const wrapper = mount(RadarChart, {
      props: { radarData },
    })
    // 5 level polygons + 3 series polygons = 8
    const allPolygons = wrapper.findAll('polygon')
    expect(allPolygons.length).toBe(5 + 3)
  })

  it('shows tooltip content on hover over a data point', async () => {
    const radarData: RadarData = {
      axes: ['JS', 'Python', 'Go'],
      series: [
        { user_id: 1, name: 'Alice', color: '#3b82f6', values: [4, 3, 5] },
      ],
    }
    const wrapper = mount(RadarChart, {
      props: { radarData },
    })

    // Before hover, tooltip should not be visible
    expect(wrapper.find('.absolute').exists()).toBe(false)

    // Find the first data point circle and trigger mouseenter
    const circles = wrapper.findAll('circle')
    expect(circles.length).toBeGreaterThan(0)

    await circles[0].trigger('mouseenter', {
      offsetX: 100,
      offsetY: 100,
    })

    // Tooltip should now be visible with content
    const tooltip = wrapper.find('.absolute')
    expect(tooltip.exists()).toBe(true)
    expect(tooltip.text()).toContain('Alice')
    expect(tooltip.text()).toContain('JS')
    expect(tooltip.text()).toContain('4')
  })

  it('hides tooltip on mouseleave', async () => {
    const radarData: RadarData = {
      axes: ['JS', 'Python', 'Go'],
      series: [{ user_id: 1, name: 'Alice', color: '#3b82f6', values: [4, 3, 5] }],
    }
    const wrapper = mount(RadarChart, { props: { radarData } })
    const circles = wrapper.findAll('circle')
    // First show the tooltip
    await circles[0].trigger('mouseenter', { offsetX: 100, offsetY: 100 })
    expect(wrapper.find('.absolute').exists()).toBe(true)
    // Then hide it on mouseleave
    await circles[0].trigger('mouseleave')
    expect(wrapper.find('.absolute').exists()).toBe(false)
  })

  it('handles empty data gracefully (no crash with empty axes/series)', () => {
    const radarData: RadarData = { axes: [], series: [] }
    const wrapper = mount(RadarChart, {
      props: { radarData },
    })
    expect(wrapper.find('svg').exists()).toBe(true)
    expect(wrapper.findAll('line').length).toBe(0)
    expect(wrapper.findAll('circle').length).toBe(0)
  })
})
