<script setup lang="ts">
import { onMounted, computed } from 'vue'
import AppLayout from '@/layouts/AppLayout.vue'
import RadarChart from '@/components/RadarChart.vue'
import Overview from '@/components/Overview.vue'
import { useAuthStore } from '@/stores/auth'
import { useSkillsStore } from '@/stores/skills'
import { useEvaluationsStore } from '@/stores/evaluations'

const authStore = useAuthStore()
const skillsStore = useSkillsStore()
const evalStore = useEvaluationsStore()

const currentPeriod = computed(() => {
  const now = new Date()
  return `${now.getFullYear()}-Q${Math.ceil((now.getMonth() + 1) / 3)}`
})

onMounted(async () => {
  await skillsStore.fetchSkillsets()
  if (skillsStore.skillsets.length > 0 && authStore.user) {
    await evalStore.fetchRadarData(
      [authStore.user.id],
      skillsStore.skillsets[0].id,
      currentPeriod.value,
    )
  }
})

const totalSkills = computed(() =>
  skillsStore.skillsets.reduce((sum, s) => sum + (s.skill_count || 0), 0),
)

const averageScore = computed(() => {
  if (!evalStore.radarData || evalStore.radarData.series.length === 0) return 0
  const vals = evalStore.radarData.series[0].values
  if (vals.length === 0) return 0
  return Math.round((vals.reduce((a, b) => a + b, 0) / vals.length) * 10) / 10
})

const skillsRated = computed(() => {
  if (!evalStore.radarData || evalStore.radarData.series.length === 0) return 0
  return evalStore.radarData.series[0].values.filter((v) => v > 0).length
})

const completionPct = computed(() => {
  if (totalSkills.value === 0) return 0
  return Math.round((skillsRated.value / totalSkills.value) * 100)
})
</script>

<template>
  <AppLayout>
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="mb-8">
        <h1 class="text-2xl font-bold text-gray-900">
          My Dashboard
        </h1>
        <p class="text-gray-500 mt-1">
          Welcome back, {{ authStore.user?.name }}
        </p>
      </div>

      <!-- Overview Stats -->
      <Overview
        :total-skills="totalSkills"
        :average-score="averageScore"
        :skills-rated="skillsRated"
        :completion-percentage="completionPct"
      />

      <!-- Radar + Self-evaluation links -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mt-8">
        <!-- Radar Chart -->
        <div class="lg:col-span-2 card p-6">
          <h2 class="text-lg font-semibold text-gray-900 mb-4">
            Skills Overview
          </h2>
          <div v-if="evalStore.radarData && evalStore.radarData.axes.length > 0" class="flex justify-center">
            <RadarChart :radar-data="evalStore.radarData" :size="420" />
          </div>
          <div v-else class="flex items-center justify-center h-64 text-gray-400">
            <p>No evaluation data available yet</p>
          </div>
        </div>

        <!-- Skillsets / Quick Actions -->
        <div class="space-y-4">
          <div class="card p-5">
            <h3 class="text-sm font-semibold text-gray-900 mb-3">
              Self Evaluation
            </h3>
            <div class="space-y-2">
              <RouterLink
                v-for="skillset in skillsStore.skillsets"
                :key="skillset.id"
                :to="`/self-evaluation/${skillset.id}`"
                class="flex items-center justify-between p-3 rounded-lg border border-gray-200 hover:border-primary/30 hover:bg-primary-light/30 transition-colors group"
              >
                <span class="text-sm font-medium text-gray-700 group-hover:text-primary-dark">
                  {{ skillset.name }}
                </span>
                <svg class="w-4 h-4 text-gray-400 group-hover:text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </RouterLink>
            </div>
            <p
              v-if="skillsStore.skillsets.length === 0"
              class="text-sm text-gray-400"
            >
              No skillsets available
            </p>
          </div>

          <div class="card p-5">
            <h3 class="text-sm font-semibold text-gray-900 mb-2">
              Current Period
            </h3>
            <p class="text-2xl font-bold text-primary">
              {{ currentPeriod }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
