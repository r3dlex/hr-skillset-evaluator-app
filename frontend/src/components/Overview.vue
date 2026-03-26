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
      <p class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
        Total Skills
      </p>
      <p class="text-2xl font-bold text-gray-900">
        {{ totalSkills }}
      </p>
    </div>

    <div class="card p-5">
      <p class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
        Average Score
      </p>
      <p class="text-2xl font-bold text-gray-900">
        {{ averageScore > 0 ? averageScore.toFixed(1) : '--' }}
      </p>
    </div>

    <div class="card p-5">
      <p class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
        Skills Rated
      </p>
      <p class="text-2xl font-bold text-gray-900">
        {{ skillsRated }}
      </p>
    </div>

    <div class="card p-5">
      <p class="text-xs font-medium text-gray-500 uppercase tracking-wider mb-1">
        Completion
      </p>
      <div class="flex items-end gap-2">
        <p class="text-2xl font-bold text-gray-900">
          {{ completionPercentage }}%
        </p>
      </div>
      <div class="mt-2 h-1.5 bg-gray-100 rounded-full overflow-hidden">
        <div
          class="h-full bg-primary rounded-full transition-all duration-500"
          :style="{ width: `${completionPercentage}%` }"
        />
      </div>
    </div>
  </div>
</template>
