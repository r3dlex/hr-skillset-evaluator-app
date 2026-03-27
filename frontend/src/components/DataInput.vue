<script setup lang="ts">
import type { Skill, GapAnalysisItem } from '@/types'
import ScoreSlider from './ScoreSlider.vue'
import { computed } from 'vue'

const props = defineProps<{
  skills: Skill[]
  scores: Record<number, number | null>
  readonly: boolean
  gapItems?: GapAnalysisItem[]
}>()

const avgsBySkillId = computed(() => {
  const map: Record<number, { team_avg: number | null; role_avg: number | null }> = {}
  if (props.gapItems) {
    for (const item of props.gapItems) {
      if (item.skill_id) {
        map[item.skill_id] = { team_avg: item.team_avg ?? null, role_avg: item.role_avg ?? null }
      }
    }
  }
  return map
})

const emit = defineEmits<{
  'update:score': [skillId: number, value: number]
}>()

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
  <div>
    <h3 class="text-lg font-semibold mb-4" :style="{ color: 'var(--color-text-primary)' }">
      Score Data
    </h3>

    <!-- Table header -->
    <div
      class="flex items-center gap-4 px-4 py-2 text-xs font-medium uppercase tracking-wider"
      :style="{ color: 'var(--color-text-secondary)' }"
    >
      <div class="flex-[3] min-w-0">Skill</div>
      <div class="w-20 shrink-0">Priority</div>
      <div class="flex-[3] min-w-0">Score (0-5)</div>
      <template v-if="gapItems">
        <div class="w-20 shrink-0 text-center">Team Avg</div>
        <div class="w-20 shrink-0 text-center">Role Avg</div>
      </template>
    </div>

    <!-- Skill rows -->
    <div class="divide-y" :style="{ borderColor: 'var(--color-border)' }">
      <div
        v-for="skill in skills"
        :key="skill.id"
        class="flex items-center gap-4 px-4 py-3"
      >
        <div class="flex-[3] min-w-0 text-sm font-medium" :style="{ color: 'var(--color-text-primary)' }">
          {{ skill.name }}
        </div>
        <div class="w-20 shrink-0">
          <span
            class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium"
            :class="priorityColor(skill.priority)"
          >
            {{ skill.priority }}
          </span>
        </div>
        <div class="flex-[3] min-w-0">
          <ScoreSlider
            :model-value="scores[skill.id] ?? 0"
            :disabled="readonly"
            @update:model-value="emit('update:score', skill.id, $event)"
          />
        </div>
        <template v-if="gapItems">
          <div class="w-20 shrink-0 text-center">
            <span
              v-if="avgsBySkillId[skill.id]?.team_avg != null"
              class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-sky-100 text-sky-700"
            >
              {{ avgsBySkillId[skill.id].team_avg!.toFixed(1) }}
            </span>
            <span v-else class="text-xs" :style="{ color: 'var(--color-text-muted)' }">—</span>
          </div>
          <div class="w-20 shrink-0 text-center">
            <span
              v-if="avgsBySkillId[skill.id]?.role_avg != null"
              class="inline-flex items-center px-2 py-0.5 rounded text-xs font-semibold bg-violet-100 text-violet-700"
            >
              {{ avgsBySkillId[skill.id].role_avg!.toFixed(1) }}
            </span>
            <span v-else class="text-xs" :style="{ color: 'var(--color-text-muted)' }">—</span>
          </div>
        </template>
      </div>
    </div>

    <p v-if="skills.length === 0" class="text-center py-8" :style="{ color: 'var(--color-text-muted)' }">
      No skills to display
    </p>
  </div>
</template>
