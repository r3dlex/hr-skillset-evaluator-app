import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import OnboardingChecklist from '../OnboardingChecklist.vue'
import { useOnboardingStore } from '@/stores/onboarding'
import { useAuthStore } from '@/stores/auth'

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

const mockRouter = {
  push: vi.fn(),
}

vi.mock('vue-router', () => ({
  useRouter: () => mockRouter,
}))

function mountChecklist() {
  return mount(OnboardingChecklist, {
    global: {
      stubs: {
        RouterLink: {
          template: '<a><slot /></a>',
          props: ['to'],
        },
      },
    },
  })
}

describe('OnboardingChecklist', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('renders correct number of steps for manager role', () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const wrapper = mountChecklist()
    // Manager has 5 steps
    const steps = wrapper.findAll('[class*="flex items-center gap-2.5"]')
    expect(steps.length).toBe(5)
  })

  it('renders correct number of steps for user role', () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 2,
      email: 'b@b.com',
      name: 'Bob',
      role: 'user',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const wrapper = mountChecklist()
    // User has 4 steps
    const steps = wrapper.findAll('[class*="flex items-center gap-2.5"]')
    expect(steps.length).toBe(4)
  })

  it('shows progress count', () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const onboardingStore = useOnboardingStore()
    onboardingStore.completedSteps = ['import_xlsx']
    const wrapper = mountChecklist()
    expect(wrapper.text()).toContain('1/5')
  })

  it('completed steps have line-through styling', () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const onboardingStore = useOnboardingStore()
    onboardingStore.completedSteps = ['import_xlsx']
    const wrapper = mountChecklist()
    const completedLabel = wrapper.find('.line-through')
    expect(completedLabel.exists()).toBe(true)
    expect(completedLabel.text()).toBe('Import skill matrix')
  })

  it('completed steps have green checkmark circle', () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const onboardingStore = useOnboardingStore()
    onboardingStore.completedSteps = ['import_xlsx']
    const wrapper = mountChecklist()
    const greenCircle = wrapper.find('.border-green-500.bg-green-500')
    expect(greenCircle.exists()).toBe(true)
  })

  it('pending steps have empty circle (border only)', () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const wrapper = mountChecklist()
    const emptyCircles = wrapper.findAll('.border-white\\/30')
    // All 5 steps should be pending
    expect(emptyCircles.length).toBe(5)
  })

  it('clicking step with route navigates', async () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const wrapper = mountChecklist()
    // First step (import_xlsx) has route '/settings/skillsets'
    const steps = wrapper.findAll('[class*="flex items-center gap-2.5"]')
    await steps[0].trigger('click')
    expect(mockRouter.push).toHaveBeenCalledWith('/settings/skillsets')
  })

  it('dismiss button calls dismiss', async () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const onboardingStore = useOnboardingStore()
    const dismissSpy = vi.spyOn(onboardingStore, 'dismiss').mockResolvedValue()
    const wrapper = mountChecklist()

    const dismissBtn = wrapper.findAll('button').find(b => b.text() === 'Dismiss')
    expect(dismissBtn).toBeDefined()
    await dismissBtn!.trigger('click')
    expect(dismissSpy).toHaveBeenCalled()
  })

  it('emits start-tour on tour button click', async () => {
    const authStore = useAuthStore()
    authStore.user = {
      id: 1,
      email: 'a@b.com',
      name: 'Alice',
      role: 'manager',
      team: { id: 1, name: 'Eng' },
      location: 'Berlin',
      active: true,
    }
    const wrapper = mountChecklist()
    const tourBtn = wrapper.findAll('button').find(b => b.text() === 'Take a tour')
    expect(tourBtn).toBeDefined()
    await tourBtn!.trigger('click')
    expect(wrapper.emitted('start-tour')).toBeTruthy()
  })
})
