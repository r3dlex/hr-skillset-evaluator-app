<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSkillsStore } from '@/stores/skills'

const router = useRouter()
const authStore = useAuthStore()
const skillsStore = useSkillsStore()

onMounted(() => {
  if (skillsStore.skillsets.length === 0) {
    skillsStore.fetchSkillsets()
  }
})

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>

<template>
  <aside class="fixed left-0 top-0 bottom-0 w-[260px] bg-sidebar text-white flex flex-col z-30">
    <!-- Logo -->
    <div class="px-6 py-5 border-b border-white/10">
      <h1 class="text-lg font-semibold tracking-tight">
        HR Skillset Evaluator
      </h1>
    </div>

    <!-- Navigation -->
    <nav class="px-4 py-4 space-y-1">
      <RouterLink
        to="/dashboard"
        class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors hover:bg-white/10"
        active-class="bg-white/15 text-white"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
        Dashboard
      </RouterLink>

      <RouterLink
        v-if="authStore.isManager"
        to="/settings/skillsets"
        class="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors hover:bg-white/10"
        active-class="bg-white/15 text-white"
      >
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        Settings
      </RouterLink>
    </nav>

    <!-- Skillsets -->
    <div class="px-4 py-3 flex-1 overflow-y-auto">
      <h2 class="px-3 mb-2 text-xs font-semibold uppercase tracking-wider text-white/50">
        Skillsets
      </h2>
      <div class="space-y-0.5">
        <RouterLink
          v-for="skillset in skillsStore.skillsets"
          :key="skillset.id"
          :to="`/skillsets/${skillset.id}`"
          class="flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-colors hover:bg-white/10 text-white/70"
          active-class="bg-primary/20 text-primary-light"
        >
          <span class="w-2 h-2 rounded-full bg-primary shrink-0" />
          {{ skillset.name }}
        </RouterLink>
        <p
          v-if="skillsStore.skillsets.length === 0 && !skillsStore.loading"
          class="px-3 py-2 text-sm text-white/40"
        >
          No skillsets yet
        </p>
      </div>
    </div>

    <!-- User info -->
    <div class="px-4 py-4 border-t border-white/10">
      <div class="flex items-center gap-3">
        <div class="w-9 h-9 rounded-full bg-primary/30 flex items-center justify-center text-sm font-semibold text-primary-light shrink-0">
          {{ authStore.user?.name?.charAt(0)?.toUpperCase() || '?' }}
        </div>
        <div class="flex-1 min-w-0">
          <p class="text-sm font-medium truncate">
            {{ authStore.user?.name }}
          </p>
          <p class="text-xs text-white/50 truncate">
            {{ authStore.user?.email }}
          </p>
        </div>
        <button
          class="p-1.5 rounded-lg hover:bg-white/10 transition-colors text-white/50 hover:text-white"
          title="Sign out"
          @click="handleLogout"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
        </button>
      </div>
    </div>
  </aside>
</template>
