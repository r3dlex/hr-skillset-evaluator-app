<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(defineProps<{
  modelValue: number
  disabled?: boolean
}>(), {
  disabled: false,
})

const emit = defineEmits<{
  'update:modelValue': [value: number]
}>()

const percentage = computed(() => (props.modelValue / 5) * 100)

function handleInput(event: Event) {
  const target = event.target as HTMLInputElement
  emit('update:modelValue', Number(target.value))
}
</script>

<template>
  <div class="flex items-center gap-3">
    <input
      type="range"
      min="0"
      max="5"
      step="1"
      :value="modelValue"
      :disabled="disabled"
      class="flex-1 h-2 rounded-full appearance-none cursor-pointer disabled:opacity-50 disabled:cursor-not-allowed"
      :style="{
        background: `linear-gradient(to right, var(--color-primary) 0%, var(--color-primary) ${percentage}%, var(--color-border) ${percentage}%, var(--color-border) 100%)`,
        accentColor: 'var(--color-primary)',
      }"
      @input="handleInput"
    />
    <span
      class="w-8 h-8 rounded-lg flex items-center justify-center text-sm font-semibold shrink-0"
      :style="
        modelValue > 0
          ? { backgroundColor: 'color-mix(in srgb, var(--color-primary) 10%, transparent)', color: 'var(--color-primary)' }
          : { backgroundColor: 'var(--color-border)', color: 'var(--color-text-muted)' }
      "
    >
      {{ modelValue }}
    </span>
  </div>
</template>
