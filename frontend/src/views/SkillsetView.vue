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
import { assessments as assessmentsApi } from '@/api'
import type { Assessment } from '@/types'
import { useScreenContext } from '@/composables/useScreenContext'

const route = useRoute()
const skillsStore = useSkillsStore()
const evalStore = useEvaluationsStore()
const teamStore = useTeamStore()
const authStore = useAuthStore()

const activeTab = ref<'chart' | 'table' | 'gap'>('chart')
const selectedTeamId = ref<number | null>(null)
const selectedUserId = ref<number | null>(null)
const selectedGroupId = ref<number | 'all' | null>(null)
const selectedLocation = ref<string>('')  // '' means "All"

const skillsetId = computed(() => Number(route.params.id))

// Assessments — replaces the old "periods" concept
const availableAssessments = ref<Assessment[]>([])
const selectedAssessmentId = ref<number | null>(null)
const assessmentsLoading = ref(false)
const showNewAssessmentForm = ref(false)
const newAssessmentName = ref('')
const newAssessmentDescription = ref('')
const creatingAssessment = ref(false)

const currentAssessment = computed(() =>
  availableAssessments.value.find(a => a.id === selectedAssessmentId.value) || null
)
const currentPeriod = computed(() => currentAssessment.value?.name || '')

async function fetchAssessments() {
  if (!skillsetId.value) return

  assessmentsLoading.value = true
  try {
    // Always fetch all assessments so the dropdown is never empty
    let list = await assessmentsApi.list()

    // If a specific user is selected, also check which assessments have data for them
    // (but still show all assessments in the dropdown so managers can evaluate new ones)
    availableAssessments.value = list
    if (list.length > 0) {
      // Try to restore persisted assessment from store (by name)
      const persistedName = teamStore.selectedAssessmentName
      const persistedMatch = persistedName ? list.find(a => a.name === persistedName) : null
      // Keep current selection if valid, or use persisted, or default to first
      if (list.find(a => a.id === selectedAssessmentId.value)) {
        // current selection still valid
      } else if (persistedMatch) {
        selectedAssessmentId.value = persistedMatch.id
      } else {
        selectedAssessmentId.value = list[0].id
      }
    }
  } finally {
    assessmentsLoading.value = false
  }
}

async function createAssessment() {
  if (!newAssessmentName.value.trim()) return
  creatingAssessment.value = true
  try {
    const assessment = await assessmentsApi.create(
      newAssessmentName.value.trim(),
      newAssessmentDescription.value.trim() || undefined,
    )
    availableAssessments.value.unshift(assessment)
    selectedAssessmentId.value = assessment.id
    showNewAssessmentForm.value = false
    newAssessmentName.value = ''
    newAssessmentDescription.value = ''
    loadData()
  } catch (e) {
    // If it already exists, re-fetch to show it
    await fetchAssessments()
  } finally {
    creatingAssessment.value = false
  }
}

const skillGroups = computed(() => {
  return skillsStore.currentSkillset?.skill_groups || []
})

// Track the last specific group so we can restore it when leaving "All"
const lastSpecificGroupId = ref<number | null>(null)

const isAllSelected = computed(() => selectedGroupId.value === 'all')

// Unique locations from current team members for region filter
const availableLocations = computed(() => {
  const locs = new Set<string>()
  for (const m of teamStore.members) {
    if (m.location) locs.add(m.location)
  }
  return Array.from(locs).sort()
})

const selectedGroup = computed(() => {
  if (selectedGroupId.value === 'all') return null
  if (!selectedGroupId.value) return skillGroups.value[0] || null
  return skillGroups.value.find(g => g.id === selectedGroupId.value) || skillGroups.value[0] || null
})

// Auto-set selectedGroupId to first group when groups become available
watch(skillGroups, (groups) => {
  if (groups.length > 0 && !selectedGroupId.value) {
    selectedGroupId.value = groups[0].id
    lastSpecificGroupId.value = groups[0].id
  }
}, { immediate: true })

// When switching to radar chart and "All" is selected, restore last specific group
watch(activeTab, () => {
  if (activeTab.value === 'chart' && selectedGroupId.value === 'all') {
    selectedGroupId.value = lastSpecificGroupId.value || skillGroups.value[0]?.id || null
  }
  loadData()
})

const allSkills = computed(() => {
  if (!skillsStore.currentSkillset?.skill_groups) return []
  // Filter by selected group when not "all"
  if (selectedGroup.value) {
    return selectedGroup.value.skills || []
  }
  return skillsStore.currentSkillset.skill_groups.flatMap((g) => g.skills)
})

// Saved scores snapshot: frozen when evaluations load, represents the DB state
const savedScores = ref<Record<number, number | null>>({})

// Pending scores: local edits not yet saved
const pendingScores = ref<Record<number, number>>({})
const saving = ref(false)
const saveMessage = ref('')

function captureInitialScores() {
  const map: Record<number, number | null> = {}
  for (const ev of evalStore.evaluations) {
    map[ev.skill_id] = ev.manager_score
  }
  savedScores.value = map
  pendingScores.value = {}
}

// scoreMap merges saved scores with pending (unsaved) edits for the slider display
const scoreMap = computed(() => {
  const map: Record<number, number | null> = { ...savedScores.value }
  for (const [skillId, score] of Object.entries(pendingScores.value)) {
    map[Number(skillId)] = score
  }
  return map
})

const hasPendingChanges = computed(() => {
  for (const [skillId, score] of Object.entries(pendingScores.value)) {
    const saved = savedScores.value[Number(skillId)]
    if (saved !== score) return true
  }
  return false
})

const pendingChangeCount = computed(() => {
  let count = 0
  for (const [skillId, score] of Object.entries(pendingScores.value)) {
    if (savedScores.value[Number(skillId)] !== score) count++
  }
  return count
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

async function switchTeam(teamId: number) {
  selectedTeamId.value = teamId
  selectedUserId.value = null
  await teamStore.fetchMembers(teamId)
  await fetchAssessments()
  loadData()
}

onMounted(async () => {
  await skillsStore.fetchSkillset(skillsetId.value)
  if (authStore.isManager) {
    await teamStore.fetchTeams()
    if (teamStore.teams.length > 0) {
      // Prefer persisted team from Dashboard, then user's own team, then first
      const persisted = teamStore.selectedTeamId
      const validPersisted = persisted && teamStore.teams.some(t => t.id === persisted)
      const teamId = validPersisted ? persisted : (authStore.user?.team?.id || teamStore.teams[0].id)
      selectedTeamId.value = teamId
      await teamStore.fetchMembers(teamId)
    }
  }
  // Default selectedGroupId to first group
  if (skillGroups.value.length > 0 && !selectedGroupId.value) {
    selectedGroupId.value = skillGroups.value[0].id
    lastSpecificGroupId.value = skillGroups.value[0].id
  }
  await fetchAssessments()
  loadData()
})

watch(skillsetId, async () => {
  // Reset to Radar Chart tab when navigating between skillsets
  activeTab.value = 'chart'
  selectedGroupId.value = null
  await skillsStore.fetchSkillset(skillsetId.value)
  await fetchAssessments()
  loadData()
})

watch(selectedUserId, async () => {
  await fetchAssessments()
  loadData()
})

function selectGroup(groupId: number | 'all') {
  selectedGroupId.value = groupId
  if (groupId !== 'all') {
    lastSpecificGroupId.value = groupId
  }
  loadData()
}

function loadData() {
  // Radar: if a specific user is selected, show only that user; otherwise show all team members
  const radarUserIds = selectedUserId.value
    ? [selectedUserId.value]
    : authStore.isManager
      ? Array.from(teamStore.selectedMemberIds)
      : authStore.user ? [authStore.user.id] : []

  // For radar chart, always use a specific group; for table/gap, allow "all" (no group filter)
  const groupId = isAllSelected.value ? undefined : selectedGroup.value?.id

  if (radarUserIds.length > 0) {
    // Radar always needs a group — use first group if "all" is somehow active
    const radarGroupId = groupId || skillGroups.value[0]?.id
    evalStore.fetchRadarData(radarUserIds, skillsetId.value, currentPeriod.value, radarGroupId)
  }

  const userId = effectiveUserId.value
  if (userId) {
    evalStore.fetchEvaluations(userId, skillsetId.value, currentPeriod.value, groupId).then(() => {
      captureInitialScores()
    })
    evalStore.fetchGapAnalysis(userId, skillsetId.value, currentPeriod.value, groupId, {
      teamId: selectedTeamId.value || undefined,
      location: selectedLocation.value || undefined,
    })
  }

  updateScreenContext()
}

// -- AI Assistant screen context --
const { setScreenContext } = useScreenContext()

function updateScreenContext() {
  // Send the actual selected user (null = "All members" / team overview)
  // Don't send effectiveUserId because that defaults to first member
  const contextUserId = selectedUserId.value || null
  setScreenContext({
    screen: 'skillset',
    skillset_id: skillsetId.value,
    skill_group_id: typeof selectedGroupId.value === 'number' ? selectedGroupId.value : null,
    user_id: contextUserId,
    team_id: selectedTeamId.value,
    period: currentPeriod.value,
    active_tab: activeTab.value,
    // Include how many team members are visible for the LLM's awareness
    visible_member_count: selectedUserId.value ? 1 : teamStore.members.length,
    visible_member_names: selectedUserId.value
      ? undefined
      : teamStore.members.map(m => m.name || m.email).slice(0, 20),
  })
}

watch([activeTab, selectedGroupId, selectedUserId, selectedAssessmentId, selectedTeamId], () => {
  updateScreenContext()
})

function handleScoreUpdate(skillId: number, score: number) {
  pendingScores.value[skillId] = score
}

async function handleSave() {
  if (!selectedUserId.value || !currentPeriod.value) return
  saving.value = true
  saveMessage.value = ''
  try {
    const scores = Object.entries(pendingScores.value)
      .filter(([skillId, score]) => savedScores.value[Number(skillId)] !== score)
      .map(([skillId, score]) => ({ skill_id: Number(skillId), score }))

    if (scores.length === 0) return

    await evalStore.updateManagerScores(
      selectedUserId.value,
      currentPeriod.value,
      scores,
    )
    // Re-capture saved scores from the updated evaluations
    captureInitialScores()
    saveMessage.value = 'Scores saved successfully!'
    setTimeout(() => { saveMessage.value = '' }, 3000)
  } catch (e) {
    saveMessage.value = e instanceof Error ? e.message : 'Failed to save'
  } finally {
    saving.value = false
  }
}

function handleDiscard() {
  pendingScores.value = {}
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
          <label class="text-sm" :style="{ color: 'var(--color-text-secondary)' }">Assessment:</label>
          <select
            v-model="selectedAssessmentId"
            class="input-field w-auto"
            :disabled="assessmentsLoading || availableAssessments.length === 0"
            @change="teamStore.setSelectedAssessment(currentAssessment?.name || ''); loadData()"
          >
            <option v-if="availableAssessments.length === 0" :value="null">No assessments</option>
            <option v-for="a in availableAssessments" :key="a.id" :value="a.id">{{ a.name }}</option>
          </select>
          <button
            v-if="authStore.isManager"
            class="inline-flex items-center justify-center w-8 h-8 rounded-lg transition-colors"
            :style="{
              backgroundColor: showNewAssessmentForm
                ? 'color-mix(in srgb, var(--color-primary) 15%, transparent)'
                : 'transparent',
              color: 'var(--color-primary)',
              border: '1px solid var(--color-border)',
            }"
            title="Create new assessment"
            @click="showNewAssessmentForm = !showNewAssessmentForm"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
          </button>
        </div>
      </div>

      <!-- New Assessment Form -->
      <div
        v-if="showNewAssessmentForm"
        class="mb-6 card p-4"
      >
        <h3 class="text-sm font-semibold mb-3" :style="{ color: 'var(--color-text-primary)' }">Create New Assessment</h3>
        <div class="flex items-end gap-3">
          <div class="flex-1">
            <label class="block text-xs font-medium mb-1" :style="{ color: 'var(--color-text-secondary)' }">Name</label>
            <input
              v-model="newAssessmentName"
              class="input-field w-full"
              placeholder="e.g. 2026-Q1, Annual Review 2026"
              @keyup.enter="createAssessment"
            />
          </div>
          <div class="flex-1">
            <label class="block text-xs font-medium mb-1" :style="{ color: 'var(--color-text-secondary)' }">Description (optional)</label>
            <input
              v-model="newAssessmentDescription"
              class="input-field w-full"
              placeholder="Brief description"
              @keyup.enter="createAssessment"
            />
          </div>
          <button
            class="btn-primary text-sm"
            :disabled="!newAssessmentName.trim() || creatingAssessment"
            @click="createAssessment"
          >
            {{ creatingAssessment ? 'Creating...' : 'Create' }}
          </button>
          <button
            class="btn-secondary text-sm"
            @click="showNewAssessmentForm = false"
          >
            Cancel
          </button>
        </div>
      </div>

      <!-- Save message -->
      <div
        v-if="saveMessage"
        class="mb-4 px-4 py-3 rounded-lg text-sm"
        :class="saveMessage.includes('success') ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'"
      >
        {{ saveMessage }}
      </div>

      <!-- Team & Member selector for managers -->
      <div v-if="authStore.isManager" class="mb-6 flex items-end gap-4">
        <div v-if="teamStore.teams.length > 1">
          <label class="block text-sm font-medium mb-2" :style="{ color: 'var(--color-text-secondary)' }">Team</label>
          <select
            v-model="selectedTeamId"
            class="input-field w-52"
            @change="switchTeam(Number(selectedTeamId))"
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
        <div v-if="teamStore.members.length > 0">
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
        <div v-if="availableLocations.length > 1">
          <label class="block text-sm font-medium mb-2" :style="{ color: 'var(--color-text-secondary)' }">Region</label>
          <select
            v-model="selectedLocation"
            class="input-field w-44"
            @change="loadData()"
          >
            <option value="">All</option>
            <option v-for="loc in availableLocations" :key="loc" :value="loc">{{ loc }}</option>
          </select>
        </div>
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
          {{ tab === 'gap' ? 'Gap Analysis' : tab === 'chart' ? 'Radar Chart' : 'Evaluation Table' }}
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
            <p v-if="authStore.isManager" class="text-sm text-center max-w-xs mb-4" :style="{ color: 'var(--color-text-secondary)' }">
              No evaluations yet. Start by evaluating team members on this skillset.
            </p>
            <button
              v-if="authStore.isManager"
              class="btn-primary text-sm inline-flex items-center gap-2"
              @click="activeTab = 'table'"
            >
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
              </svg>
              Start Evaluation
            </button>
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

      <!-- Evaluation Table View -->
      <div v-if="activeTab === 'table'" class="card p-6">
        <!-- Start evaluation prompt when no user selected (manager) -->
        <div
          v-if="authStore.isManager && !selectedUserId"
          class="mb-4 px-4 py-3 rounded-lg flex items-center justify-between"
          :style="{
            backgroundColor: 'color-mix(in srgb, var(--color-primary) 6%, transparent)',
            border: '1px solid color-mix(in srgb, var(--color-primary) 20%, var(--color-border))',
          }"
        >
          <div class="flex items-center gap-2 text-sm" :style="{ color: 'var(--color-text-secondary)' }">
            <svg class="w-4 h-4" :style="{ color: 'var(--color-primary)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Select a team member above to start evaluating their skills.
          </div>
        </div>
        <DataInput
          :skills="allSkills"
          :scores="scoreMap"
          :readonly="!authStore.isManager || !selectedUserId"
          :gap-items="evalStore.gapAnalysis"
          :saved-scores="savedScores"
          @update:score="handleScoreUpdate"
        />

        <!-- Save / Discard bar -->
        <div
          v-if="hasPendingChanges"
          class="mt-4 flex items-center justify-between px-4 py-3 rounded-lg"
          :style="{
            backgroundColor: 'color-mix(in srgb, var(--color-primary) 6%, transparent)',
            border: '1px solid color-mix(in srgb, var(--color-primary) 20%, var(--color-border))',
          }"
        >
          <span class="text-sm" :style="{ color: 'var(--color-text-secondary)' }">
            {{ pendingChangeCount }} unsaved change{{ pendingChangeCount !== 1 ? 's' : '' }}
          </span>
          <div class="flex items-center gap-2">
            <button
              class="btn-secondary text-sm"
              @click="handleDiscard"
            >
              Discard
            </button>
            <button
              class="btn-primary text-sm inline-flex items-center gap-1.5"
              :disabled="saving"
              @click="handleSave"
            >
              <svg v-if="!saving" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
              {{ saving ? 'Saving...' : 'Save Evaluation' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Gap Analysis View -->
      <div v-if="activeTab === 'gap'" class="card p-6">
        <GapAnalysis :items="evalStore.gapAnalysis" />
      </div>
    </div>
  </AppLayout>
</template>
