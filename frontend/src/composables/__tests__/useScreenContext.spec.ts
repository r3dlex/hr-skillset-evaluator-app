import { describe, it, expect, vi, beforeEach } from 'vitest'
import { ref } from 'vue'

// Mock vue-router before importing the composable
vi.mock('vue-router', () => ({
  useRoute: vi.fn().mockReturnValue({
    name: ref('dashboard'),
  }),
}))

import { useScreenContext, getScreenContext } from '../useScreenContext'
import { useRoute } from 'vue-router'

describe('getScreenContext', () => {
  it('returns a screen context object', () => {
    const ctx = getScreenContext()
    expect(ctx).toBeDefined()
    expect(typeof ctx.screen).toBe('string')
  })

  it('returns object with screen property', () => {
    const ctx = getScreenContext()
    expect(ctx).toHaveProperty('screen')
  })
})

describe('useScreenContext composable', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(useRoute).mockReturnValue({ name: ref('dashboard') } as any)
  })

  it('provides setScreenContext function', () => {
    const { setScreenContext } = useScreenContext()
    expect(typeof setScreenContext).toBe('function')
  })

  it('provides screenContext ref', () => {
    const { screenContext } = useScreenContext()
    expect(screenContext).toBeDefined()
    expect(typeof screenContext.value.screen).toBe('string')
  })

  it('setScreenContext updates the context', () => {
    const { setScreenContext, screenContext } = useScreenContext()
    setScreenContext({ screen: 'skillset', skillset_id: 42 })
    expect(screenContext.value.screen).toBe('skillset')
    expect(screenContext.value.skillset_id).toBe(42)
  })

  it('setScreenContext replaces entire context', () => {
    const { setScreenContext, screenContext } = useScreenContext()
    setScreenContext({ screen: 'settings' })
    expect(screenContext.value.screen).toBe('settings')
    expect(screenContext.value.skillset_id).toBeUndefined()
  })

  it('setScreenContext and getScreenContext are in sync', () => {
    const { setScreenContext } = useScreenContext()
    setScreenContext({ screen: 'self-evaluation', skillset_id: 10 })
    const ctx = getScreenContext()
    expect(ctx.screen).toBe('self-evaluation')
    expect(ctx.skillset_id).toBe(10)
  })

  it('handles route name change via watch', () => {
    const routeName = ref('dashboard')
    vi.mocked(useRoute).mockReturnValue({ name: routeName } as any)
    const { screenContext } = useScreenContext()
    // The watch (immediate: true) should set screen from route.name
    expect(typeof screenContext.value.screen).toBe('string')
  })
})
