<script setup lang="ts">
import type { Skill, GapAnalysisItem } from '@/types'
import { computed } from 'vue'

const props = defineProps<{
  skills: Skill[]
  scores: Record<number, number | null>
  readonly: boolean
  gapItems?: GapAnalysisItem[]
  savedScores?: Record<number, number | null>
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

// savedScores represents the original values before the current editing session
// so "Current" column stays frozen while the user adjusts sliders

const isEvaluating = computed(() => !props.readonly)

const emit = defineEmits<{
  'update:score': [skillId: number, value: number]
}>()

function priorityColor(priority: string): string {
  switch (priority) {
    case 'critical': return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-300'
    case 'high': return 'bg-orange-100 text-orange-800 dark:bg-orange-900/30 dark:text-orange-300'
    case 'medium': return 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300'
    default: return 'bg-gray-100 text-gray-600 dark:bg-gray-800 dark:text-gray-400'
  }
}

function formatScore(score: number | null | undefined): string {
  if (score === null || score === undefined) return '?'
  return String(score)
}
</script>

<template>
  <div>
    <div class="flex items-center justify-between mb-4">
      <h3 class="text-lg font-semibold" :style="{ color: 'var(--color-text-primary)' }">
        {{ isEvaluating ? 'Evaluation Table' : 'Evaluation Data' }}
      </h3>
      <!-- Mode indicator -->
      <div v-if="isEvaluating" class="flex items-center gap-2">
        <span
          class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold"
          :style="{
            backgroundColor: 'color-mix(in srgb, var(--color-success, #22c55e) 12%, transparent)',
            color: 'var(--color-success, #22c55e)',
            border: '1px solid color-mix(in srgb, var(--color-success, #22c55e) 25%, transparent)',
          }"
        >
          <span class="w-1.5 h-1.5 rounded-full animate-pulse" :style="{ backgroundColor: 'var(--color-success, #22c55e)' }" />
          Editing scores
        </span>
      </div>
      <div v-else class="flex items-center gap-2">
        <span
          class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium"
          :style="{
            backgroundColor: 'color-mix(in srgb, var(--color-text-muted) 10%, transparent)',
            color: 'var(--color-text-muted)',
          }"
        >
          View only
        </span>
      </div>
    </div>

    <!-- Table header -->
    <div
      class="flex items-center gap-3 px-4 py-2 text-xs font-medium uppercase tracking-wider"
      :style="{ color: 'var(--color-text-secondary)' }"
    >
      <div class="flex-[3] min-w-0">Skill</div>
      <div class="w-16 shrink-0 text-center">Priority</div>
      <div class="w-16 shrink-0 text-center">Current Score</div>
      <div v-if="isEvaluating" class="flex-1 min-w-0">New Score</div>
      <div v-else class="flex-1 min-w-0">Score (0-5)</div>
      <div class="w-10 shrink-0 text-center"></div>
      <template v-if="gapItems">
        <div class="w-16 shrink-0 text-center">Team</div>
        <div class="w-16 shrink-0 text-center">Role</div>
      </template>
    </div>

    <!-- Skill rows -->
    <div class="divide-y" :style="{ borderColor: 'var(--color-border)' }">
      <div
        v-for="skill in skills"
        :key="skill.id"
        class="flex items-center gap-3 px-4 py-3 transition-colors"
        :class="isEvaluating ? 'hover:bg-white/5' : ''"
      >
        <!-- Skill name -->
        <div class="flex-[3] min-w-0 text-sm font-medium" :style="{ color: 'var(--color-text-primary)' }">
          {{ skill.name }}
        </div>

        <!-- Priority -->
        <div class="w-16 shrink-0 text-center">
          <span
            class="inline-flex items-center px-1.5 py-0.5 rounded text-[10px] font-semibold uppercase"
            :class="priorityColor(skill.priority)"
          >
            {{ skill.priority }}
          </span>
        </div>

        <!-- Current score (saved before this editing session) -->
        <div class="w-16 shrink-0 text-center">
          <span
            class="inline-flex items-center justify-center w-8 h-8 rounded-lg text-sm font-semibold"
            :style="
              savedScores?.[skill.id] != null
                ? {
                    backgroundColor: 'color-mix(in srgb, var(--color-info, #3b82f6) 12%, transparent)',
                    color: 'var(--color-info, #3b82f6)',
                  }
                : {
                    backgroundColor: 'var(--color-border)',
                    color: 'var(--color-text-muted)',
                    fontStyle: 'italic',
                  }
            "
            :title="savedScores?.[skill.id] != null ? `Saved score: ${savedScores[skill.id]}` : 'No evaluation yet'"
          >
            {{ formatScore(savedScores?.[skill.id]) }}
          </span>
        </div>

        <!-- Score slider -->
        <div class="flex-1 min-w-0">
          <input
            type="range"
            min="0"
            max="5"
            step="1"
            :value="scores[skill.id] ?? 0"
            :disabled="readonly"
            class="w-full h-2 rounded-full appearance-none cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
            :style="{
              background: `linear-gradient(to right, var(--color-primary) 0%, var(--color-primary) ${((scores[skill.id] ?? 0) / 5) * 100}%, var(--color-border) ${((scores[skill.id] ?? 0) / 5) * 100}%, var(--color-border) 100%)`,
              accentColor: 'var(--color-primary)',
            }"
            @input="emit('update:score', skill.id, Number(($event.target as HTMLInputElement).value))"
          />
        </div>

        <!-- New score value badge -->
        <div class="w-10 shrink-0 text-center">
          <span
            class="inline-flex items-center justify-center w-8 h-8 rounded-lg text-sm font-semibold"
            :style="
              (scores[skill.id] ?? 0) > 0
                ? { backgroundColor: 'color-mix(in srgb, var(--color-primary) 10%, transparent)', color: 'var(--color-primary)' }
                : { backgroundColor: 'var(--color-border)', color: 'var(--color-text-muted)' }
            "
          >
            {{ scores[skill.id] ?? 0 }}
          </span>
        </div>

        <!-- Gap analysis columns -->
        <template v-if="gapItems">
          <div class="w-16 shrink-0 text-center">
            <span
              v-if="avgsBySkillId[skill.id]?.team_avg != null"
              class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-semibold bg-sky-100 text-sky-700 dark:bg-sky-900/30 dark:text-sky-300"
            >
              {{ avgsBySkillId[skill.id].team_avg!.toFixed(1) }}
            </span>
            <span v-else class="text-xs" :style="{ color: 'var(--color-text-muted)' }">—</span>
          </div>
          <div class="w-16 shrink-0 text-center">
            <span
              v-if="avgsBySkillId[skill.id]?.role_avg != null"
              class="inline-flex items-center px-1.5 py-0.5 rounded text-xs font-semibold bg-violet-100 text-violet-700 dark:bg-violet-900/30 dark:text-violet-300"
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
