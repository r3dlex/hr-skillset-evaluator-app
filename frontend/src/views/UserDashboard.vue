<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import AppLayout from '@/layouts/AppLayout.vue'
import RadarChart from '@/components/RadarChart.vue'
import Overview from '@/components/Overview.vue'
import { useAuthStore } from '@/stores/auth'
import { useSkillsStore } from '@/stores/skills'
import { useEvaluationsStore } from '@/stores/evaluations'

const authStore = useAuthStore()
const skillsStore = useSkillsStore()
const evalStore = useEvaluationsStore()

const availablePeriods = computed(() => {
  const periods: string[] = []
  const now = new Date()
  for (let i = 0; i < 8; i++) {
    const d = new Date(now.getFullYear(), now.getMonth() - i * 3, 1)
    const q = Math.ceil((d.getMonth() + 1) / 3)
    const p = `${d.getFullYear()}-Q${q}`
    if (!periods.includes(p)) periods.push(p)
  }
  return periods
})

const selectedPeriod = ref(availablePeriods.value[0])
const currentPeriod = computed(() => selectedPeriod.value)

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
        <h1 class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
          My Dashboard
        </h1>
        <p class="mt-1" :style="{ color: 'var(--color-text-secondary)' }">
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
          <h2 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
            Skills Overview
          </h2>
          <div v-if="evalStore.radarData && evalStore.radarData.axes.length > 0" class="flex justify-center">
            <RadarChart :radar-data="evalStore.radarData" :size="420" />
          </div>
          <div v-else class="flex flex-col items-center justify-center h-64">
            <div
              class="w-14 h-14 mb-4 rounded-2xl flex items-center justify-center"
              :style="{ backgroundColor: 'color-mix(in srgb, var(--color-primary) 10%, transparent)' }"
            >
              <svg class="w-7 h-7" :style="{ color: 'var(--color-primary)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
              </svg>
            </div>
            <h3 class="text-base font-semibold mb-1" :style="{ color: 'var(--color-text-primary)' }">
              Your skills journey starts here
            </h3>
            <p class="text-sm mb-4 text-center max-w-xs" :style="{ color: 'var(--color-text-secondary)' }">
              Your manager hasn't evaluated you yet, but you can start with a self-evaluation!
            </p>
            <RouterLink
              v-if="skillsStore.skillsets.length > 0"
              :to="`/self-evaluation/${skillsStore.skillsets[0].id}`"
              class="btn-primary text-sm inline-flex items-center gap-2"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              Start self-evaluation
            </RouterLink>
          </div>
        </div>

        <!-- Skillsets / Quick Actions -->
        <div class="space-y-4">
          <div class="card p-5">
            <h3 class="text-sm font-semibold mb-3" :style="{ color: 'var(--color-text-primary)' }">
              Self Evaluation
            </h3>
            <div class="space-y-2">
              <RouterLink
                v-for="skillset in skillsStore.skillsets"
                :key="skillset.id"
                :to="`/self-evaluation/${skillset.id}`"
                class="flex items-center justify-between p-3 rounded-lg transition-colors group"
                :style="{ border: '1px solid var(--color-border)' }"
              >
                <span class="text-sm font-medium" :style="{ color: 'var(--color-text-secondary)' }">
                  {{ skillset.name }}
                </span>
                <svg class="w-4 h-4" :style="{ color: 'var(--color-text-muted)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
                </svg>
              </RouterLink>
            </div>
            <p
              v-if="skillsStore.skillsets.length === 0"
              class="text-sm"
              :style="{ color: 'var(--color-text-muted)' }"
            >
              No skillsets available
            </p>
          </div>

          <div class="card p-5">
            <h3 class="text-sm font-semibold mb-2" :style="{ color: 'var(--color-text-primary)' }">
              Current Period
            </h3>
            <p class="text-2xl font-bold" :style="{ color: 'var(--color-primary)' }">
              {{ currentPeriod }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </AppLayout>
</template>
