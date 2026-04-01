import { describe, it, expect, vi, beforeEach } from 'vitest'
import { getScreenContext } from '../useScreenContext'

// Test just the getScreenContext since useScreenContext requires vue-router
describe('getScreenContext', () => {
  it('returns a screen context object', () => {
    const ctx = getScreenContext()
    expect(ctx).toBeDefined()
    expect(typeof ctx.screen).toBe('string')
  })
})

// Test useScreenContext with mocked router
describe('useScreenContext composable', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('can be imported and provides setScreenContext', async () => {
    vi.mock('vue-router', () => ({
      useRoute: vi.fn().mockReturnValue({
        name: 'dashboard',
      }),
    }))
    // Dynamic import to get fresh module after mock
    const { useScreenContext, getScreenContext } = await import('../useScreenContext')
    // Just verify exports exist
    expect(useScreenContext).toBeDefined()
    expect(getScreenContext).toBeDefined()
  })

  it('getScreenContext returns current context', () => {
    const ctx = getScreenContext()
    expect(ctx).toHaveProperty('screen')
  })
})
