import { describe, it, expect, vi, beforeEach } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useOnboardingStore } from '../onboarding'
import { useAuthStore } from '../auth'

vi.mock('@/api', () => ({
  auth: {
    login: vi.fn(),
    logout: vi.fn(),
    fetchMe: vi.fn(),
  },
  onboarding: {
    completeStep: vi.fn(),
    dismiss: vi.fn(),
  },
}))

import { onboarding as onboardingApi } from '@/api'

const mockManager = {
  id: 1,
  email: 'alice@example.com',
  name: 'Alice',
  role: 'manager' as const,
  team: { id: 1, name: 'Engineering' },
  location: 'Berlin',
  active: true,
  onboarding: {
    completed_steps: ['import_xlsx', 'review_skillsets'],
    dismissed: false,
  },
}

const mockUser = {
  id: 2,
  email: 'bob@example.com',
  name: 'Bob',
  role: 'user' as const,
  team: { id: 1, name: 'Engineering' },
  location: 'Berlin',
  active: true,
  onboarding: {
    completed_steps: [],
    dismissed: false,
  },
}

describe('useOnboardingStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('has correct initial state (empty steps, not dismissed)', () => {
    const store = useOnboardingStore()
    expect(store.completedSteps).toEqual([])
    expect(store.dismissed).toBe(false)
  })

  it('syncFromUser populates from auth store', () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    store.syncFromUser()
    expect(store.completedSteps).toEqual(['import_xlsx', 'review_skillsets'])
    expect(store.dismissed).toBe(false)
  })

  it('steps returns manager steps when isManager', () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    expect(store.steps.length).toBe(5)
    expect(store.steps[0].id).toBe('import_xlsx')
    expect(store.steps[4].id).toBe('export_data')
  })

  it('steps returns user steps when not manager', () => {
    const authStore = useAuthStore()
    authStore.user = mockUser
    const store = useOnboardingStore()
    expect(store.steps.length).toBe(4)
    expect(store.steps[0].id).toBe('view_scores')
    expect(store.steps[3].id).toBe('compare_gap')
  })

  it('progress calculates correctly', () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    store.syncFromUser()
    expect(store.progress.completed).toBe(2)
    expect(store.progress.total).toBe(5)
    expect(store.progress.percentage).toBe(40)
  })

  it('isComplete when all steps done', () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    store.completedSteps = ['import_xlsx', 'review_skillsets', 'evaluate_member', 'view_radar', 'export_data']
    expect(store.isComplete).toBe(true)
  })

  it('isVisible when not dismissed and not complete', () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    store.completedSteps = ['import_xlsx']
    store.dismissed = false
    expect(store.isVisible).toBe(true)
  })

  it('isVisible is false when dismissed', () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    store.dismissed = true
    expect(store.isVisible).toBe(false)
  })

  it('isVisible is false when complete', () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    store.completedSteps = ['import_xlsx', 'review_skillsets', 'evaluate_member', 'view_radar', 'export_data']
    expect(store.isVisible).toBe(false)
  })

  it('completeStep adds step via API', async () => {
    vi.mocked(onboardingApi.completeStep).mockResolvedValue({
      completed_steps: ['import_xlsx'],
      dismissed: false,
    })

    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()

    await store.completeStep('import_xlsx')
    expect(onboardingApi.completeStep).toHaveBeenCalledWith('import_xlsx')
    expect(store.completedSteps).toEqual(['import_xlsx'])
  })

  it('completeStep deduplicates (does not call API for already completed step)', async () => {
    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()
    store.completedSteps = ['import_xlsx']

    await store.completeStep('import_xlsx')
    expect(onboardingApi.completeStep).not.toHaveBeenCalled()
  })

  it('completeStep does optimistic update on API failure', async () => {
    vi.mocked(onboardingApi.completeStep).mockRejectedValue(new Error('Network error'))

    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()

    await store.completeStep('review_skillsets')
    expect(store.completedSteps).toContain('review_skillsets')
  })

  it('dismiss sets dismissed via API', async () => {
    vi.mocked(onboardingApi.dismiss).mockResolvedValue(undefined)

    const authStore = useAuthStore()
    authStore.user = mockManager
    const store = useOnboardingStore()

    await store.dismiss()
    expect(onboardingApi.dismiss).toHaveBeenCalled()
    expect(store.dismissed).toBe(true)
  })

  it('dismiss sets dismissed even on API failure', async () => {
    vi.mocked(onboardingApi.dismiss).mockRejectedValue(new Error('Network error'))

    const store = useOnboardingStore()
    await store.dismiss()
    expect(store.dismissed).toBe(true)
  })
})
