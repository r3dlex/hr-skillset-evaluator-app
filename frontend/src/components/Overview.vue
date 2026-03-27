<script setup lang="ts">
withDefaults(defineProps<{
  totalSkills?: number
  totalSkillsets?: number
  teamSize?: number
  averageScore?: number
  skillsRated?: number
  completionPercentage?: number
}>(), {
  totalSkills: 0,
  totalSkillsets: 0,
  teamSize: 0,
  averageScore: 0,
  skillsRated: 0,
  completionPercentage: 0,
})
</script>

<template>
  <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
    <div class="card p-5">
      <p class="text-xs font-medium uppercase tracking-wider mb-1" :style="{ color: 'var(--color-text-secondary)' }">
        Total Skills
      </p>
      <p class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
        {{ totalSkills }}
      </p>
    </div>

    <div class="card p-5">
      <p class="text-xs font-medium uppercase tracking-wider mb-1" :style="{ color: 'var(--color-text-secondary)' }">
        Average Score
      </p>
      <p class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
        {{ averageScore > 0 ? averageScore.toFixed(1) : '--' }}
      </p>
    </div>

    <div class="card p-5">
      <p class="text-xs font-medium uppercase tracking-wider mb-1" :style="{ color: 'var(--color-text-secondary)' }">
        Skills Rated
      </p>
      <p class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
        {{ skillsRated }}
      </p>
    </div>

    <div class="card p-5">
      <p class="text-xs font-medium uppercase tracking-wider mb-1" :style="{ color: 'var(--color-text-secondary)' }">
        Completion
      </p>
      <div class="flex items-end gap-2">
        <p class="text-2xl font-bold" :style="{ color: 'var(--color-text-primary)' }">
          {{ completionPercentage }}%
        </p>
      </div>
      <div class="mt-2 h-1.5 rounded-full overflow-hidden" :style="{ backgroundColor: 'var(--color-border)' }">
        <div
          class="h-full rounded-full transition-all duration-500"
          :style="{ width: `${completionPercentage}%`, backgroundColor: 'var(--color-primary)' }"
        />
      </div>
    </div>
  </div>
</template>
