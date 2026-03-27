<script setup lang="ts">
import { onMounted, inject, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSkillsStore } from '@/stores/skills'
import { useOnboardingStore } from '@/stores/onboarding'
import { useThemeStore } from '@/stores/theme'
import OnboardingChecklist from '@/components/OnboardingChecklist.vue'
import AppLogo from '@/components/logos/AppLogo.vue'
import type { TourStep } from '@/types'

const router = useRouter()
const authStore = useAuthStore()
const skillsStore = useSkillsStore()
const onboardingStore = useOnboardingStore()
const themeStore = useThemeStore()

const startTour = inject<(steps: TourStep[]) => void>('startTour')

// Filter skillsets by user's job_title — managers/admins see all
const visibleSkillsets = computed(() => {
  if (authStore.isManager) return skillsStore.skillsets
  const userJobTitle = authStore.user?.job_title
  return skillsStore.skillsets.filter((s) => {
    const roles = s.applicable_roles
    // Empty list or undefined = applicable to all roles
    if (!roles || roles.length === 0) return true
    // Check if user's job title matches any applicable role (case-insensitive)
    if (!userJobTitle) return true
    return roles.some((r) => r.toLowerCase() === userJobTitle.toLowerCase())
  })
})

onMounted(() => {
  if (skillsStore.skillsets.length === 0) {
    skillsStore.fetchSkillsets()
  }
  onboardingStore.syncFromUser()
})

function handleStartTour() {
  const tourSteps: TourStep[] = authStore.isManager
    ? [
        { target: '[data-tour="dashboard-link"]', title: 'Dashboard', content: 'Your main hub for team overview and stats.', position: 'right' },
        { target: '[data-tour="settings-link"]', title: 'Settings', content: 'Manage skillsets, import xlsx files, and configure skill groups.', position: 'right' },
        { target: '[data-tour="skillsets-section"]', title: 'Skillsets', content: 'Quick links to each skillset for evaluating team members.', position: 'right' },
        { target: '[data-tour="user-info"]', title: 'Your Profile', content: 'View your account info and sign out from here.', position: 'top' },
      ]
    : [
        { target: '[data-tour="dashboard-link"]', title: 'Your Dashboard', content: 'See your evaluation scores, radar chart, and self-evaluation links.', position: 'right' },
        { target: '[data-tour="skillsets-section"]', title: 'Skillsets', content: 'Navigate to each skillset to view your evaluations and radar charts.', position: 'right' },
        { target: '[data-tour="user-info"]', title: 'Your Profile', content: 'View your account info and sign out from here.', position: 'top' },
      ]
  startTour?.(tourSteps)
}

async function handleLogout() {
  await authStore.logout()
  router.push('/login')
}
</script>

<template>
  <aside
    class="fixed left-0 top-0 bottom-0 flex flex-col z-30 transition-all duration-200 ease-in-out overflow-hidden"
    :style="{
      width: themeStore.sidebarCollapsed ? 'var(--sidebar-collapsed-width)' : 'var(--sidebar-width)',
      backgroundColor: 'var(--color-sidebar-bg)',
      color: 'var(--color-sidebar-active)',
    }"
  >
    <!-- Logo -->
    <div
      class="flex items-center border-b border-white/10 shrink-0 transition-all duration-200"
      :class="themeStore.sidebarCollapsed ? 'px-3 py-4 justify-center' : 'px-5 py-4'"
    >
      <AppLogo :size="28" :collapsed="themeStore.sidebarCollapsed" />
    </div>

    <!-- Navigation -->
    <nav class="px-2 py-3 space-y-0.5 shrink-0">
      <!-- Dashboard -->
      <RouterLink
        to="/dashboard"
        data-tour="dashboard-link"
        class="flex items-center gap-3 rounded-lg text-sm font-medium transition-colors hover:bg-white/10 relative group"
        :class="themeStore.sidebarCollapsed ? 'px-0 py-2.5 justify-center' : 'px-3 py-2.5'"
        active-class="bg-white/15 text-white"
        :style="{ color: 'var(--color-sidebar-text)' }"
      >
        <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        </svg>
        <span v-if="!themeStore.sidebarCollapsed" class="truncate">Dashboard</span>
        <!-- Tooltip when collapsed -->
        <div
          v-if="themeStore.sidebarCollapsed"
          class="absolute left-full ml-2 px-2.5 py-1.5 bg-gray-900 text-white text-xs rounded-md whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50"
        >
          Dashboard
        </div>
      </RouterLink>

      <!-- Settings (manager only) -->
      <RouterLink
        v-if="authStore.isManager"
        to="/settings/skillsets"
        data-tour="settings-link"
        class="flex items-center gap-3 rounded-lg text-sm font-medium transition-colors hover:bg-white/10 relative group"
        :class="themeStore.sidebarCollapsed ? 'px-0 py-2.5 justify-center' : 'px-3 py-2.5'"
        active-class="bg-white/15 text-white"
        :style="{ color: 'var(--color-sidebar-text)' }"
      >
        <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
        <span v-if="!themeStore.sidebarCollapsed" class="truncate">Settings</span>
        <div
          v-if="themeStore.sidebarCollapsed"
          class="absolute left-full ml-2 px-2.5 py-1.5 bg-gray-900 text-white text-xs rounded-md whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50"
        >
          Settings
        </div>
      </RouterLink>
    </nav>

    <!-- Onboarding Checklist -->
    <OnboardingChecklist
      v-if="onboardingStore.isVisible && !themeStore.sidebarCollapsed"
      @start-tour="handleStartTour"
    />

    <!-- Skillsets -->
    <div
      class="py-3 flex-1 min-h-0"
      :class="themeStore.sidebarCollapsed ? 'px-2 overflow-hidden' : 'px-2 overflow-y-auto scrollbar-thin'"
      data-tour="skillsets-section"
    >
      <h2
        v-if="!themeStore.sidebarCollapsed"
        class="px-3 mb-2 text-xs font-semibold uppercase tracking-wider"
        style="color: var(--color-sidebar-text); opacity: 0.6;"
      >
        Skillsets
      </h2>
      <div class="space-y-0.5">
        <RouterLink
          v-for="skillset in visibleSkillsets"
          :key="skillset.id"
          :to="`/skillsets/${skillset.id}`"
          class="flex items-center gap-3 rounded-lg text-sm transition-colors hover:bg-white/10 relative group"
          :class="themeStore.sidebarCollapsed ? 'px-0 py-2.5 justify-center' : 'px-3 py-2'"
          active-class="bg-white/10"
          :style="{ color: 'var(--color-sidebar-text)' }"
        >
          <!-- Skillset icon (always shown — same icon for expanded and collapsed) -->
          <svg class="w-5 h-5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24" :style="{ opacity: themeStore.sidebarCollapsed ? 1 : 0.7 }">
            <path v-if="skillset.name.toLowerCase().includes('domain')" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            <path v-else-if="skillset.name.toLowerCase().includes('fullstack') || skillset.name.toLowerCase().includes('stack')" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
            <path v-else-if="skillset.name.toLowerCase().includes('soft')" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
            <path v-else-if="skillset.name.toLowerCase().includes('product')" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4" />
            <path v-else-if="skillset.name.toLowerCase().includes('ai') || skillset.name.toLowerCase().includes('data')" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
            <path v-else-if="skillset.name.toLowerCase().includes('ux')" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
            <path v-else stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
          </svg>
          <span v-if="!themeStore.sidebarCollapsed" class="truncate">{{ skillset.name }}</span>
          <div
            v-if="themeStore.sidebarCollapsed"
            class="absolute left-full ml-2 px-2.5 py-1.5 bg-gray-900 text-white text-xs rounded-md whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50"
          >
            {{ skillset.name }}
          </div>
        </RouterLink>
        <p
          v-if="visibleSkillsets.length === 0 && !skillsStore.loading && !themeStore.sidebarCollapsed"
          class="px-3 py-2 text-sm"
          style="color: var(--color-sidebar-text); opacity: 0.5;"
        >
          No skillsets yet
        </p>
      </div>
    </div>

    <!-- User info -->
    <div class="border-t border-white/10 shrink-0" data-tour="user-info">
      <div
        class="flex items-center transition-all duration-200"
        :class="themeStore.sidebarCollapsed ? 'px-2 py-3 justify-center' : 'px-4 py-3 gap-3'"
      >
        <div
          class="rounded-full flex items-center justify-center text-sm font-semibold shrink-0 relative group"
          :class="themeStore.sidebarCollapsed ? 'w-8 h-8' : 'w-9 h-9'"
          :style="{ backgroundColor: 'color-mix(in srgb, var(--color-primary) 30%, transparent)', color: 'var(--color-primary-light)' }"
        >
          {{ authStore.user?.name?.charAt(0)?.toUpperCase() || '?' }}
          <div
            v-if="themeStore.sidebarCollapsed"
            class="absolute left-full ml-2 px-2.5 py-1.5 bg-gray-900 text-white text-xs rounded-md whitespace-nowrap opacity-0 pointer-events-none group-hover:opacity-100 transition-opacity z-50"
          >
            {{ authStore.user?.name }}
          </div>
        </div>
        <template v-if="!themeStore.sidebarCollapsed">
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium truncate" style="color: var(--color-sidebar-active);">
              {{ authStore.user?.name }}
            </p>
            <p class="text-xs truncate" style="color: var(--color-sidebar-text); opacity: 0.7;">
              {{ authStore.user?.email }}
            </p>
          </div>
          <button
            class="p-1.5 rounded-lg hover:bg-white/10 transition-colors"
            :style="{ color: 'var(--color-sidebar-text)' }"
            title="Sign out"
            @click="handleLogout"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
          </button>
        </template>
      </div>
    </div>

    <!-- Collapse toggle -->
    <div class="border-t border-white/10 shrink-0">
      <button
        class="w-full flex items-center justify-end px-4 py-3 hover:bg-white/10 transition-colors"
        :style="{ color: 'var(--color-sidebar-text)' }"
        :title="themeStore.sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'"
        @click="themeStore.toggleSidebar()"
      >
        <!-- Chevron left (collapse) or chevron right (expand) -->
        <svg
          class="w-5 h-5 transition-transform duration-200"
          :class="themeStore.sidebarCollapsed ? 'rotate-180' : ''"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
      </button>
    </div>
  </aside>
</template>
