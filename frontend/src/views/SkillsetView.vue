<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from '@/layouts/AppLayout.vue'
import RadarChart from '@/components/RadarChart.vue'
import TeamLegend from '@/components/TeamLegend.vue'
import GapAnalysis from '@/components/GapAnalysis.vue'
import DataInput from '@/components/DataInput.vue'
import { useSkillsStore } from '@/stores/skills'
import { useEvaluationsStore } from '@/stores/evaluations'
import { useTeamStore } from '@/stores/team'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const skillsStore = useSkillsStore()
const evalStore = useEvaluationsStore()
const teamStore = useTeamStore()
const authStore = useAuthStore()

const activeTab = ref<'chart' | 'table' | 'gap'>('chart')
const selectedUserId = ref<number | null>(null)

const skillsetId = computed(() => Number(route.params.id))

const currentPeriod = computed(() => {
  const now = new Date()
  return `${now.getFullYear()}-Q${Math.ceil((now.getMonth() + 1) / 3)}`
})

const allSkills = computed(() => {
  if (!skillsStore.currentSkillset?.skill_groups) return []
  return skillsStore.currentSkillset.skill_groups.flatMap((g) => g.skills)
})

const scoreMap = computed(() => {
  const map: Record<number, number | null> = {}
  for (const ev of evalStore.evaluations) {
    map[ev.skill_id] = ev.manager_score
  }
  return map
})

onMounted(async () => {
  await skillsStore.fetchSkillset(skillsetId.value)
  if (authStore.isManager) {
    await teamStore.fetchTeams()
    if (teamStore.teams.length > 0 && authStore.user?.team) {
      await teamStore.fetchMembers(authStore.user.team.id)
    }
  }
  loadData()
})

watch(skillsetId, () => {
  skillsStore.fetchSkillset(skillsetId.value)
  loadData()
})

function loadData() {
  const userIds = authStore.isManager
    ? Array.from(teamStore.selectedMemberIds)
    : authStore.user ? [authStore.user.id] : []

  if (userIds.length > 0) {
    evalStore.fetchRadarData(userIds, skillsetId.value, currentPeriod.value)
  }

  const userId = selectedUserId.value || authStore.user?.id
  if (userId) {
    evalStore.fetchEvaluations(userId, skillsetId.value, currentPeriod.value)
    evalStore.fetchGapAnalysis(userId, skillsetId.value, currentPeriod.value)
  }
}

async function handleScoreUpdate(skillId: number, score: number) {
  if (!selectedUserId.value) return
  await evalStore.updateManagerScores(
    selectedUserId.value,
    currentPeriod.value,
    [{ skill_id: skillId, score }],
  )
}
</script>

<template>
  <AppLayout>
    <div class="max-w-7xl mx-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">
            {{ skillsStore.currentSkillset?.name || 'Loading...' }}
          </h1>
          <p class="text-gray-500 mt-1">
            {{ skillsStore.currentSkillset?.description }}
          </p>
        </div>
        <div class="text-sm text-gray-500">
          Period: <span class="font-semibold text-gray-700">{{ currentPeriod }}</span>
        </div>
      </div>

      <!-- Member selector for managers -->
      <div v-if="authStore.isManager && teamStore.members.length > 0" class="mb-6">
        <label class="block text-sm font-medium text-gray-700 mb-2">Team Member</label>
        <select
          v-model="selectedUserId"
          class="w-64 px-4 py-2.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary outline-none bg-white"
          @change="loadData()"
        >
          <option :value="null">All members</option>
          <option
            v-for="member in teamStore.members"
            :key="member.id"
            :value="member.id"
          >
            {{ member.name }}
          </option>
        </select>
      </div>

      <!-- Tab navigation -->
      <div class="flex gap-1 mb-6 bg-gray-100 rounded-lg p-1 w-fit">
        <button
          v-for="tab in (['chart', 'table', 'gap'] as const)"
          :key="tab"
          class="px-4 py-2 text-sm font-medium rounded-md transition-colors capitalize"
          :class="activeTab === tab ? 'bg-white text-gray-900 shadow-sm' : 'text-gray-500 hover:text-gray-700'"
          @click="activeTab = tab"
        >
          {{ tab === 'gap' ? 'Gap Analysis' : tab === 'chart' ? 'Radar Chart' : 'Data Table' }}
        </button>
      </div>

      <!-- Chart View -->
      <div v-if="activeTab === 'chart'" class="grid grid-cols-1 lg:grid-cols-4 gap-6">
        <div class="lg:col-span-3 card p-6">
          <div v-if="evalStore.radarData && evalStore.radarData.axes.length > 0" class="flex justify-center">
            <RadarChart :radar-data="evalStore.radarData" :size="500" />
          </div>
          <div v-else class="flex items-center justify-center h-80 text-gray-400">
            No data available
          </div>
        </div>

        <div class="space-y-4">
          <TeamLegend
            v-if="evalStore.radarData"
            :series="evalStore.radarData.series"
          />
        </div>
      </div>

      <!-- Data Table View -->
      <div v-if="activeTab === 'table'" class="card p-6">
        <DataInput
          :skills="allSkills"
          :scores="scoreMap"
          :readonly="!authStore.isManager || !selectedUserId"
          @update:score="handleScoreUpdate"
        />
      </div>

      <!-- Gap Analysis View -->
      <div v-if="activeTab === 'gap'" class="card p-6">
        <GapAnalysis :items="evalStore.gapAnalysis" />
      </div>
    </div>
  </AppLayout>
</template>
