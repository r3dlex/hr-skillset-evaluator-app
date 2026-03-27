<script setup lang="ts">
import { ref, onMounted, computed, watch, type Ref } from 'vue'
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
import { periods as periodsApi } from '@/api'

const route = useRoute()
const skillsStore = useSkillsStore()
const evalStore = useEvaluationsStore()
const teamStore = useTeamStore()
const authStore = useAuthStore()

const activeTab = ref<'chart' | 'table' | 'gap'>('chart')
const selectedUserId = ref<number | null>(null)
const selectedGroupId = ref<number | 'all' | null>(null)

const skillsetId = computed(() => Number(route.params.id))

// Dynamic periods from backend — only periods with actual data for current context
const availablePeriods = ref<string[]>([])
const selectedPeriod = ref<string>('')
const periodsLoading = ref(false)

const currentPeriod = computed(() => selectedPeriod.value)

async function fetchPeriods() {
  // Only show periods where selected person/team has data
  const userIds = selectedUserId.value
    ? [selectedUserId.value]
    : authStore.isManager
      ? teamStore.members.map((m) => m.id)
      : authStore.user ? [authStore.user.id] : []

  if (userIds.length === 0 || !skillsetId.value) return

  periodsLoading.value = true
  try {
    const list = await periodsApi.listPeriods(skillsetId.value, userIds)
    availablePeriods.value = list
    // Keep current selection if still valid, otherwise default to the most recent
    if (list.length > 0 && !list.includes(selectedPeriod.value)) {
      selectedPeriod.value = list[0]
    }
  } finally {
    periodsLoading.value = false
  }
}

const skillGroups = computed(() => {
  return skillsStore.currentSkillset?.skill_groups || []
})

const isAllSelected = computed(() => selectedGroupId.value === 'all')

const selectedGroup = computed(() => {
  if (selectedGroupId.value === 'all') return null
  if (!selectedGroupId.value) return skillGroups.value[0] || null
  return skillGroups.value.find(g => g.id === selectedGroupId.value) || null
})

// When switching to radar chart and "All" is selected, auto-select first group
watch(activeTab, (tab) => {
  if (tab === 'chart' && selectedGroupId.value === 'all') {
    selectedGroupId.value = skillGroups.value[0]?.id || null
    loadData()
  }
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

// Effective userId for evaluations and gap analysis
const effectiveUserId = computed(() => {
  if (selectedUserId.value) return selectedUserId.value
  // For managers, default to first team member
  if (authStore.isManager && teamStore.members.length > 0) {
    return teamStore.members[0].id
  }
  return authStore.user?.id || null
})

onMounted(async () => {
  await skillsStore.fetchSkillset(skillsetId.value)
  if (authStore.isManager) {
    await teamStore.fetchTeams()
    if (teamStore.teams.length > 0) {
      const teamId = authStore.user?.team?.id || teamStore.teams[0].id
      await teamStore.fetchMembers(teamId)
    }
  }
  // Default selectedGroupId to first group
  if (skillGroups.value.length > 0 && !selectedGroupId.value) {
    selectedGroupId.value = skillGroups.value[0].id
  }
  await fetchPeriods()
  loadData()
})

watch(skillsetId, async () => {
  await skillsStore.fetchSkillset(skillsetId.value)
  await fetchPeriods()
  loadData()
})

watch(selectedUserId, async () => {
  await fetchPeriods()
  loadData()
})

function selectGroup(groupId: number | 'all') {
  selectedGroupId.value = groupId
  loadData()
}

function loadData() {
  const userIds = authStore.isManager
    ? Array.from(teamStore.selectedMemberIds)
    : authStore.user ? [authStore.user.id] : []

  // For radar chart, always use a specific group; for table/gap, allow "all" (no group filter)
  const groupId = isAllSelected.value ? undefined : selectedGroup.value?.id

  if (userIds.length > 0) {
    // Radar always needs a group — use first group if "all" is somehow active
    const radarGroupId = groupId || skillGroups.value[0]?.id
    evalStore.fetchRadarData(userIds, skillsetId.value, currentPeriod.value, radarGroupId)
  }

  const userId = effectiveUserId.value
  if (userId) {
    evalStore.fetchEvaluations(userId, skillsetId.value, currentPeriod.value, groupId)
    evalStore.fetchGapAnalysis(userId, skillsetId.value, currentPeriod.value, groupId)
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
          <h1 class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
            {{ skillsStore.currentSkillset?.name || 'Loading...' }}
          </h1>
          <p class="mt-1" :style="{ color: 'var(--color-text-secondary)' }">
            {{ skillsStore.currentSkillset?.description }}
          </p>
        </div>
        <div class="flex items-center gap-2">
          <label class="text-sm" :style="{ color: 'var(--color-text-secondary)' }">Period:</label>
          <select
            v-model="selectedPeriod"
            class="input-field w-auto"
            :disabled="periodsLoading || availablePeriods.length === 0"
            @change="loadData()"
          >
            <option v-if="availablePeriods.length === 0" value="">No data available</option>
            <option v-for="p in availablePeriods" :key="p" :value="p">{{ p }}</option>
          </select>
        </div>
      </div>

      <!-- Member selector for managers -->
      <div v-if="authStore.isManager && teamStore.members.length > 0" class="mb-6">
        <label class="block text-sm font-medium mb-2" :style="{ color: 'var(--color-text-secondary)' }">Team Member</label>
        <select
          v-model="selectedUserId"
          class="input-field w-64"
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

      <!-- Skill Group Tabs -->
      <div v-if="skillGroups.length > 0" class="mb-6">
        <div
          class="flex gap-1 flex-wrap rounded-lg p-1"
          :style="{ backgroundColor: 'var(--color-bg)', border: '1px solid var(--color-border)' }"
        >
          <!-- "All" tab — hidden on radar chart -->
          <button
            v-if="activeTab !== 'chart'"
            class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors uppercase tracking-wide"
            :style="isAllSelected
              ? { backgroundColor: 'var(--color-surface)', color: 'var(--color-primary)', boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)', border: '1px solid var(--color-border)' }
              : { color: 'var(--color-text-secondary)' }
            "
            @click="selectGroup('all')"
          >
            All
          </button>
          <button
            v-for="group in skillGroups"
            :key="group.id"
            class="px-3 py-1.5 text-xs font-semibold rounded-md transition-colors uppercase tracking-wide"
            :style="selectedGroup?.id === group.id && !isAllSelected
              ? { backgroundColor: 'var(--color-surface)', color: 'var(--color-primary)', boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)', border: '1px solid var(--color-border)' }
              : { color: 'var(--color-text-secondary)' }
            "
            @click="selectGroup(group.id)"
          >
            {{ group.name }}
          </button>
        </div>
      </div>

      <!-- Tab navigation -->
      <div
        class="flex gap-1 mb-6 rounded-lg p-1 w-fit"
        :style="{ backgroundColor: 'var(--color-border)' }"
      >
        <button
          v-for="tab in (['chart', 'table', 'gap'] as const)"
          :key="tab"
          class="px-4 py-2 text-sm font-medium rounded-md transition-colors capitalize"
          :style="activeTab === tab
            ? { backgroundColor: 'var(--color-surface)', color: 'var(--color-text-primary)', boxShadow: '0 1px 2px 0 rgb(0 0 0 / 0.05)' }
            : { color: 'var(--color-text-secondary)' }
          "
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
          <div v-else class="flex flex-col items-center justify-center h-80">
            <div
              class="w-14 h-14 mb-4 rounded-2xl flex items-center justify-center"
              :style="{ backgroundColor: 'color-mix(in srgb, var(--color-primary) 10%, transparent)' }"
            >
              <svg class="w-7 h-7" :style="{ color: 'var(--color-primary)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
            </div>
            <p v-if="authStore.isManager" class="text-sm text-center max-w-xs" :style="{ color: 'var(--color-text-secondary)' }">
              No evaluations yet. Start by evaluating team members on this skillset.
            </p>
            <template v-else>
              <p class="text-sm text-center max-w-xs mb-4" :style="{ color: 'var(--color-text-secondary)' }">
                No evaluations yet. Complete a self-evaluation to see your radar chart.
              </p>
              <RouterLink
                :to="`/self-evaluation/${skillsetId}`"
                class="btn-primary text-sm inline-flex items-center gap-2"
              >
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                </svg>
                Start self-evaluation
              </RouterLink>
            </template>
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
