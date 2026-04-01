import { describe, it, expect, vi, beforeEach } from 'vitest'
import { mount, flushPromises } from '@vue/test-utils'
import { setActivePinia, createPinia } from 'pinia'
import { createRouter, createWebHistory } from 'vue-router'
import LoginView from '../LoginView.vue'

vi.mock('@/stores/auth', () => ({
  useAuthStore: vi.fn(),
}))

import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: { template: '<div/>' } },
    { path: '/login', component: { template: '<div/>' } },
    { path: '/dashboard', component: { template: '<div/>' } },
  ],
})

const mockAuthStore = {
  login: vi.fn(),
  user: null,
  isAuthenticated: false,
}

describe('LoginView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    vi.clearAllMocks()
    vi.mocked(useAuthStore).mockReturnValue(mockAuthStore as unknown as ReturnType<typeof useAuthStore>)
  })

  function mountComponent() {
    return mount(LoginView, {
      global: {
        plugins: [createPinia(), router],
        stubs: {
          AuthLayout: { template: '<div><slot /></div>' },
          SkillForgeLogo: { template: '<span/>' },
        },
      },
    })
  }

  it('renders login form', () => {
    const wrapper = mountComponent()
    expect(wrapper.find('form').exists()).toBe(true)
    expect(wrapper.find('input[type="email"]').exists()).toBe(true)
    expect(wrapper.find('input[type="password"]').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  it('shows Sign in button text initially', () => {
    const wrapper = mountComponent()
    const submitBtn = wrapper.find('button[type="submit"]')
    expect(submitBtn.text()).toBe('Sign in')
  })

  it('shows password toggle button', () => {
    const wrapper = mountComponent()
    const toggleBtn = wrapper.find('button[type="button"]')
    expect(toggleBtn.exists()).toBe(true)
  })

  it('toggles password visibility on eye button click', async () => {
    const wrapper = mountComponent()
    const passwordInput = wrapper.find('input#password')
    expect(passwordInput.attributes('type')).toBe('password')

    const toggleBtn = wrapper.find('button[type="button"]')
    await toggleBtn.trigger('click')
    expect(wrapper.find('input#password').attributes('type')).toBe('text')

    await toggleBtn.trigger('click')
    expect(wrapper.find('input#password').attributes('type')).toBe('password')
  })

  it('calls authStore.login with email and password on submit', async () => {
    mockAuthStore.login.mockResolvedValue(undefined)
    const wrapper = mountComponent()

    await wrapper.find('input#email').setValue('alice@example.com')
    await wrapper.find('input#password').setValue('secret')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(mockAuthStore.login).toHaveBeenCalledWith('alice@example.com', 'secret')
  })

  it('redirects to /dashboard on successful login', async () => {
    mockAuthStore.login.mockResolvedValue(undefined)
    const wrapper = mountComponent()

    await wrapper.find('input#email').setValue('alice@example.com')
    await wrapper.find('input#password').setValue('secret')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(router.currentRoute.value.path).toBe('/dashboard')
  })

  it('shows error message on login failure', async () => {
    mockAuthStore.login.mockRejectedValue(new Error('Invalid credentials'))
    const wrapper = mountComponent()

    await wrapper.find('input#email').setValue('bad@example.com')
    await wrapper.find('input#password').setValue('wrong')
    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.text()).toContain('Invalid credentials')
  })

  it('shows generic error message on non-Error failure', async () => {
    mockAuthStore.login.mockRejectedValue('some error')
    const wrapper = mountComponent()

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.text()).toContain('Login failed')
  })

  it('shows Signing in... text while submitting', async () => {
    let resolveLogin!: () => void
    mockAuthStore.login.mockReturnValue(new Promise<void>(resolve => { resolveLogin = resolve }))
    const wrapper = mountComponent()

    await wrapper.find('input#email').setValue('alice@example.com')
    await wrapper.find('input#password').setValue('secret')
    wrapper.find('form').trigger('submit')

    await new Promise(resolve => setTimeout(resolve, 0))
    expect(wrapper.find('button[type="submit"]').text()).toBe('Signing in...')

    resolveLogin()
    await flushPromises()
  })

  it('renders Microsoft SSO link', () => {
    const wrapper = mountComponent()
    const msLink = wrapper.find('a[href="/api/auth/microsoft"]')
    expect(msLink.exists()).toBe(true)
    expect(msLink.text()).toContain('Sign in with Microsoft')
  })
})
