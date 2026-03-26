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
      <div class="w-12 h-12 bg-primary rounded-xl flex items-center justify-center mx-auto mb-4">
        <svg class="w-7 h-7 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
      </div>
      <h2 class="text-2xl font-bold text-gray-900">
        HR Skillset Evaluator
      </h2>
      <p class="text-sm text-gray-500 mt-1">
        Sign in to your account
      </p>
    </div>

    <form @submit.prevent="handleSubmit" class="space-y-5">
      <div
        v-if="errorMessage"
        class="bg-red-50 border border-red-200 text-red-700 text-sm rounded-lg px-4 py-3"
      >
        {{ errorMessage }}
      </div>

      <div>
        <label for="email" class="block text-sm font-medium text-gray-700 mb-1.5">
          Email address
        </label>
        <input
          id="email"
          v-model="email"
          type="email"
          required
          autocomplete="email"
          class="w-full px-4 py-2.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-colors"
          placeholder="you@company.com"
        />
      </div>

      <div>
        <label for="password" class="block text-sm font-medium text-gray-700 mb-1.5">
          Password
        </label>
        <input
          id="password"
          v-model="password"
          type="password"
          required
          autocomplete="current-password"
          class="w-full px-4 py-2.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none transition-colors"
          placeholder="Enter your password"
        />
      </div>

      <button
        type="submit"
        :disabled="submitting"
        class="w-full bg-primary hover:bg-primary-dark text-white font-medium py-2.5 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed text-sm"
      >
        {{ submitting ? 'Signing in...' : 'Sign in' }}
      </button>

      <div class="relative my-4">
        <div class="absolute inset-0 flex items-center">
          <div class="w-full border-t border-gray-200" />
        </div>
        <div class="relative flex justify-center text-xs uppercase">
          <span class="bg-white px-3 text-gray-400">or</span>
        </div>
      </div>

      <button
        type="button"
        class="w-full flex items-center justify-center gap-3 bg-white border border-gray-300 hover:bg-gray-50 text-gray-700 font-medium py-2.5 px-4 rounded-lg transition-colors text-sm"
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
