<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import AppLayout from '@/layouts/AppLayout.vue'
import Overview from '@/components/Overview.vue'
import { useAuthStore } from '@/stores/auth'
import { useTeamStore } from '@/stores/team'
import { useSkillsStore } from '@/stores/skills'
import type { User } from '@/types'

const authStore = useAuthStore()
const teamStore = useTeamStore()
const skillsStore = useSkillsStore()

const selectedTeamId = ref<number | null>(null)

onMounted(async () => {
  await teamStore.fetchTeams()
  await skillsStore.fetchSkillsets()
  if (teamStore.teams.length > 0) {
    selectedTeamId.value = teamStore.teams[0].id
  }
})

watch(selectedTeamId, (id) => {
  if (id) {
    teamStore.fetchMembers(id)
  }
})

function getMemberInitial(member: User): string {
  return member.name.charAt(0).toUpperCase()
}
</script>

<template>
  <AppLayout>
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">
          Manager Dashboard
        </h1>
        <p class="text-gray-500 mt-1">
          Welcome back, {{ authStore.user?.name }}
        </p>
      </div>

      <!-- Overview Stats -->
      <Overview
        :total-skills="skillsStore.skillsets.reduce((sum, s) => sum + (s.skill_count || 0), 0)"
        :total-skillsets="skillsStore.skillsets.length"
        :team-size="teamStore.members.length"
        :completion-percentage="0"
      />

      <!-- Team Selector -->
      <div class="mt-8 mb-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">Select Team</label>
        <select
          v-model="selectedTeamId"
          class="w-64 px-4 py-2.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none bg-white"
        >
          <option
            v-for="team in teamStore.teams"
            :key="team.id"
            :value="team.id"
          >
            {{ team.name }} {{ team.member_count ? `(${team.member_count})` : '' }}
          </option>
        </select>
      </div>

      <!-- Team Members Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div
          v-for="member in teamStore.members"
          :key="member.id"
          class="card p-5 hover:shadow-md transition-shadow cursor-pointer"
        >
          <div class="flex items-center gap-4">
            <div class="w-11 h-11 rounded-full bg-primary/10 flex items-center justify-center text-primary font-semibold text-sm shrink-0">
              {{ getMemberInitial(member) }}
            </div>
            <div class="min-w-0">
              <p class="font-medium text-gray-900 truncate">{{ member.name }}</p>
              <p class="text-sm text-gray-500 truncate">{{ member.email }}</p>
            </div>
          </div>
          <div class="mt-4 flex items-center gap-2">
            <span
              class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
              :class="member.active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'"
            >
              {{ member.active ? 'Active' : 'Inactive' }}
            </span>
            <span class="text-xs text-gray-400">{{ member.location }}</span>
          </div>
          <div class="mt-3 flex gap-2">
            <RouterLink
              v-for="skillset in skillsStore.skillsets"
              :key="skillset.id"
              :to="`/skillsets/${skillset.id}`"
              class="text-xs text-primary hover:text-primary-dark font-medium"
            >
              {{ skillset.name }}
            </RouterLink>
          </div>
        </div>
      </div>

      <!-- Empty State: No teams at all -->
      <div
        v-if="teamStore.teams.length === 0 && !teamStore.loading && teamStore.members.length === 0"
        class="card p-10 text-center max-w-lg mx-auto mt-8"
      >
        <div class="w-16 h-16 mx-auto mb-5 rounded-2xl bg-primary/10 flex items-center justify-center">
          <svg class="w-8 h-8 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197m13.5-9a2.5 2.5 0 11-5 0 2.5 2.5 0 015 0z" />
          </svg>
        </div>
        <h3 class="text-lg font-bold text-gray-900 mb-2">
          Welcome! Let's set up your team evaluation
        </h3>
        <p class="text-sm text-gray-500 mb-6">
          Get started by importing your existing skill matrix or creating skillsets manually.
        </p>
        <div class="flex items-center justify-center gap-3">
          <RouterLink
            to="/settings/skillsets"
            class="btn-primary inline-flex items-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
            </svg>
            Import xlsx
          </RouterLink>
          <RouterLink
            to="/settings/skillsets"
            class="btn-secondary inline-flex items-center gap-2"
          >
            Create skillset manually
          </RouterLink>
        </div>
      </div>

      <!-- Empty State: Has teams but no members selected -->
      <div
        v-else-if="teamStore.members.length === 0 && !teamStore.loading"
        class="text-center py-16"
      >
        <svg class="w-16 h-16 mx-auto text-gray-300 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
        </svg>
        <p class="text-gray-500">Select a team to view members</p>
      </div>
    </div>
  </AppLayout>
</template>
