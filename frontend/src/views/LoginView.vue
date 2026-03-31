<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import AuthLayout from '@/layouts/AuthLayout.vue'
import { useAuthStore } from '@/stores/auth'
import SkillForgeLogo from '@/components/logos/SkillForgeLogo.vue'

const router = useRouter()
const authStore = useAuthStore()

const email = ref('')
const password = ref('')
const showPassword = ref(false)
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
      <div class="flex justify-center mb-4">
        <SkillForgeLogo :size="48" :show-text="false" />
      </div>
      <h2 class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
        SkillForge
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
        <div class="relative">
          <input
            id="password"
            v-model="password"
            :type="showPassword ? 'text' : 'password'"
            required
            autocomplete="current-password"
            class="input-field pr-10"
            placeholder="Enter your password"
          />
          <button
            type="button"
            class="absolute inset-y-0 right-0 flex items-center pr-3"
            :style="{ color: 'var(--color-text-muted)' }"
            tabindex="-1"
            @click="showPassword = !showPassword"
          >
            <!-- Eye open (password hidden) -->
            <svg v-if="!showPassword" class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z" />
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
            </svg>
            <!-- Eye closed (password visible) -->
            <svg v-else class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M3.98 8.223A10.477 10.477 0 001.934 12C3.226 16.338 7.244 19.5 12 19.5c.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88" />
            </svg>
          </button>
        </div>
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

      <a
        href="/api/auth/microsoft"
        class="w-full flex items-center justify-center gap-3 font-medium py-2.5 px-4 rounded-lg transition-colors text-sm no-underline"
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
      </a>
    </form>
  </AuthLayout>
</template>
