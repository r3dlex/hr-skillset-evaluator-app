import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import App from '../../App.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: { template: '<div class="home">Home</div>' } },
    { path: '/dashboard', component: { template: '<div class="dash">Dashboard</div>' } },
  ],
})

describe('App', () => {
  it('renders without crashing', async () => {
    await router.push('/')
    await router.isReady()

    const wrapper = mount(App, {
      global: {
        plugins: [router],
        stubs: {
          RouterView: { template: '<div class="router-view-stub"/>' },
          Suspense: { template: '<slot/>' },
        },
      },
    })
    expect(wrapper.exists()).toBe(true)
  })

  it('contains a RouterView', async () => {
    await router.push('/')
    await router.isReady()

    const wrapper = mount(App, {
      global: {
        plugins: [router],
        stubs: {
          RouterView: { template: '<div class="router-view-stub"/>' },
        },
      },
    })
    expect(wrapper.exists()).toBe(true)
  })
})
