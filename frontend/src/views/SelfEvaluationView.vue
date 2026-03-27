<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import AppLayout from '@/layouts/AppLayout.vue'
import ScoreSlider from '@/components/ScoreSlider.vue'
import { useSkillsStore } from '@/stores/skills'
import { useEvaluationsStore } from '@/stores/evaluations'
import { useAuthStore } from '@/stores/auth'
import { useChatStore } from '@/stores/chat'

const route = useRoute()
const skillsStore = useSkillsStore()
const evalStore = useEvaluationsStore()
const authStore = useAuthStore()
const chatStore = useChatStore()

async function openChatAssistant() {
  chatStore.openPanel()
  const conv = await chatStore.createConversation()
  if (conv) {
    const skillsetName = skillsStore.currentSkillset?.name || 'this skillset'
    const period = currentPeriod.value
    await chatStore.sendMessage(
      `I'd like help with my self-evaluation for ${skillsetName} in period ${period}. Can you walk me through the skills?`
    )
  }
}

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
          <h1 class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
            Self Evaluation
          </h1>
          <p class="mt-1" :style="{ color: 'var(--color-text-secondary)' }">
            {{ skillsStore.currentSkillset?.name }} - {{ currentPeriod }}
          </p>
        </div>
        <button
          :disabled="saving"
          class="btn-primary"
          @click="handleSave"
        >
          {{ saving ? 'Saving...' : 'Save Scores' }}
        </button>
      </div>

      <!-- AI Assistant Prompt -->
      <div
        class="card p-4 mb-6 flex items-center gap-3"
        :style="{ borderLeft: '4px solid var(--color-primary)' }"
      >
        <svg class="w-8 h-8 flex-shrink-0" :style="{ color: 'var(--color-primary)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
        </svg>
        <div>
          <p class="text-sm font-medium" :style="{ color: 'var(--color-text-primary)' }">
            Need help deciding your scores?
          </p>
          <p class="text-xs mt-0.5" :style="{ color: 'var(--color-text-secondary)' }">
            The AI assistant can explain proficiency levels and guide you through your self-evaluation.
          </p>
        </div>
        <button class="btn-primary text-sm ml-auto flex-shrink-0" @click="openChatAssistant">
          Ask AI Assistant
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
        <h2 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
          {{ group.name }}
        </h2>

        <div class="card overflow-hidden">
          <div
            v-for="(skill, index) in group.skills"
            :key="skill.id"
            class="flex items-center gap-6 px-6 py-4"
            :style="index < group.skills.length - 1 ? { borderBottom: '1px solid var(--color-border)' } : {}"
          >
            <!-- Skill Info -->
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="font-medium text-sm" :style="{ color: 'var(--color-text-primary)' }">{{ skill.name }}</span>
                <span
                  class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
                  :class="priorityColor(skill.priority)"
                >
                  {{ skill.priority }}
                </span>
              </div>
              <div v-if="managerScoreMap[skill.id] !== undefined" class="mt-1 text-xs" :style="{ color: 'var(--color-text-muted)' }">
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
        class="card p-10 text-center max-w-md mx-auto"
      >
        <div
          class="w-16 h-16 mx-auto mb-5 rounded-2xl flex items-center justify-center"
          :style="{ backgroundColor: 'var(--color-border)' }"
        >
          <svg class="w-8 h-8" :style="{ color: 'var(--color-text-muted)' }" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01" />
          </svg>
        </div>
        <h3 class="text-base font-semibold mb-2" :style="{ color: 'var(--color-text-primary)' }">
          No skills defined yet
        </h3>
        <p class="text-sm" :style="{ color: 'var(--color-text-secondary)' }">
          This skillset has no skills defined yet. Your manager can add skills by importing data.
        </p>
      </div>
    </div>
  </AppLayout>
</template>
