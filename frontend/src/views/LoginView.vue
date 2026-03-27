<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import AuthLayout from '@/layouts/AuthLayout.vue'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const errorMessage = ref('')
const submitting = ref(false)

async function handleSubmit() {
  errorMessage.value = ''
  submitting.value = true
  try {
    await authStore.login(email.value, password.value)
    router.push('/dashboard')
  } catch (e) {
    errorMessage.value = e instanceof Error ? e.message : 'Login failed'
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <AuthLayout>
    <div class="text-center mb-8">
      <div
        class="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-4"
        :style="{ backgroundColor: 'var(--color-primary)' }"
      >
        <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
      </div>
      <h2 class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
        HR Skillset Evaluator
      </h2>
      <p class="text-sm mt-1" :style="{ color: 'var(--color-text-secondary)' }">
        Sign in to your account
      </p>
    </div>

    <form class="space-y-5" @submit.prevent="handleSubmit">
      <div
        v-if="errorMessage"
        class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg px-4 py-3"
      >
        {{ errorMessage }}
      </div>

      <div>
        <label for="email" class="block text-sm font-medium mb-1.5" :style="{ color: 'var(--color-text-secondary)' }">
          Email address
        </label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          autocomplete="email"
          class="input-field"
          placeholder="you@company.com"
        />
      </div>

      <div>
        <label for="password" class="block text-sm font-medium mb-1.5" :style="{ color: 'var(--color-text-secondary)' }">
          Password
        </label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          autocomplete="current-password"
          class="input-field"
          placeholder="Enter your password"
        />
      </div>

      <button
        type="submit"
        :disabled="submitting"
        class="w-full btn-primary"
      >
        {{ submitting ? 'Signing in...' : 'Sign in' }}
      </button>

      <div class="relative my-4">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full" :style="{ borderTop: '1px solid var(--color-border)' }" />
        </div>
        <div class="relative flex justify-center text-xs uppercase">
          <span class="px-3" :style="{ backgroundColor: 'var(--color-surface)', color: 'var(--color-text-muted)' }">or</span>
        </div>
      </div>

      <button
        type="button"
        class="w-full flex items-center justify-center gap-3 font-medium py-2.5 px-4 rounded-lg transition-colors text-sm"
        :style="{
          backgroundColor: 'var(--color-surface)',
          border: '1px solid var(--color-border)',
          color: 'var(--color-text-secondary)',
        }"
      >
        <svg class="w-5 h-5" viewBox="0 0 21 21" fill="none">
          <path d="M10 0H0V10H10V0Z" fill="#F25022" />
          <path d="M21 0H11V10H21V0Z" fill="#7FBA00" />
          <path d="M10 11H0V21H10V11Z" fill="#00A4EF" />
          <path d="M21 11H11V21H21V11Z" fill="#FFB900" />
        </svg>
        Sign in with Microsoft
      </button>
    </form>
  </AuthLayout>
</template>
