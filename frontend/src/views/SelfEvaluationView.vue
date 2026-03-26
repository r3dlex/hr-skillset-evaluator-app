<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from '@/layouts/AppLayout.vue'
import ScoreSlider from '@/components/ScoreSlider.vue'
import { useSkillsStore } from '@/stores/skills'
import { useEvaluationsStore } from '@/stores/evaluations'
import { useAuthStore } from '@/stores/auth'

const route = useRoute()
const skillsStore = useSkillsStore()
const evalStore = useEvaluationsStore()
const authStore = useAuthStore()

const skillsetId = computed(() => Number(route.params.skillsetId))
const saving = ref(false)
const saveMessage = ref('')
const selfScores = ref<Record<number, number>>({})

const currentPeriod = computed(() => {
  const now = new Date()
  return `${now.getFullYear()}-Q${Math.ceil((now.getMonth() + 1) / 3)}`
})

const managerScoreMap = computed(() => {
  const map: Record<number, number | null> = {}
  for (const ev of evalStore.evaluations) {
    map[ev.skill_id] = ev.manager_score
  }
  return map
})

onMounted(async () => {
  await skillsStore.fetchSkillset(skillsetId.value)
  if (authStore.user) {
    await evalStore.fetchEvaluations(
      authStore.user.id,
      skillsetId.value,
      currentPeriod.value,
    )
    // Initialize self scores from existing evaluations
    for (const ev of evalStore.evaluations) {
      if (ev.self_score !== null) {
        selfScores.value[ev.skill_id] = ev.self_score
      }
    }
  }
})

function updateScore(skillId: number, value: number) {
  selfScores.value[skillId] = value
}

async function handleSave() {
  saving.value = true
  saveMessage.value = ''
  try {
    const scores = Object.entries(selfScores.value).map(([id, score]) => ({
      skill_id: Number(id),
      score,
    }))
    await evalStore.updateSelfScores(currentPeriod.value, scores)
    saveMessage.value = 'Scores saved successfully!'
    setTimeout(() => { saveMessage.value = '' }, 3000)
  } catch (e) {
    saveMessage.value = e instanceof Error ? e.message : 'Failed to save'
  } finally {
    saving.value = false
  }
}

function priorityColor(priority: string): string {
  switch (priority) {
    case 'critical': return 'bg-red-100 text-red-800'
    case 'high': return 'bg-orange-100 text-orange-800'
    case 'medium': return 'bg-blue-100 text-blue-800'
    default: return 'bg-gray-100 text-gray-600'
  }
}
</script>

<template>
  <AppLayout>
    <div class="max-w-4xl mx-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-8">
        <div>
          <h1 class="text-2xl font-bold text-gray-900">
            Self Evaluation
          </h1>
          <p class="text-gray-500 mt-1">
            {{ skillsStore.currentSkillset?.name }} - {{ currentPeriod }}
          </p>
        </div>
        <button
          :disabled="saving"
          class="bg-primary hover:bg-primary-dark text-white font-medium py-2.5 px-6 rounded-lg transition-colors disabled:opacity-50 text-sm"
          @click="handleSave"
        >
          {{ saving ? 'Saving...' : 'Save Scores' }}
        </button>
      </div>

      <!-- Save message -->
      <div
        v-if="saveMessage"
        class="mb-6 px-4 py-3 rounded-lg text-sm"
        :class="saveMessage.includes('success') ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'"
      >
        {{ saveMessage }}
      </div>

      <!-- Skill Groups -->
      <div
        v-for="group in skillsStore.currentSkillset?.skill_groups"
        :key="group.id"
        class="mb-8"
      >
        <h2 class="text-lg font-semibold text-gray-900 mb-4">
          {{ group.name }}
        </h2>

        <div class="card overflow-hidden">
          <div
            v-for="(skill, index) in group.skills"
            :key="skill.id"
            class="flex items-center gap-6 px-6 py-4"
            :class="index < group.skills.length - 1 ? 'border-b border-gray-100' : ''"
          >
            <!-- Skill Info -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="font-medium text-gray-900 text-sm">{{ skill.name }}</span>
                <span
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                  :class="priorityColor(skill.priority)"
                >
                  {{ skill.priority }}
                </span>
              </div>
              <div v-if="managerScoreMap[skill.id] !== undefined" class="mt-1 text-xs text-gray-400">
                Manager score: {{ managerScoreMap[skill.id] ?? 'Not rated' }}
              </div>
            </div>

            <!-- Self Score Slider -->
            <div class="w-64 shrink-0">
              <ScoreSlider
                :model-value="selfScores[skill.id] ?? 0"
                :disabled="false"
                @update:model-value="updateScore(skill.id, $event)"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div
        v-if="!skillsStore.currentSkillset?.skill_groups?.length && !skillsStore.loading"
        class="text-center py-16"
      >
        <p class="text-gray-400">No skills defined for this skillset</p>
      </div>
    </div>
  </AppLayout>
</template>
