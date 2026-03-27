<script setup lang="ts">
</script>

<template>
  <div
    class="min-h-screen flex items-center justify-center"
    :style="{ backgroundColor: 'var(--color-text-primary, #1e293b)' }"
  >
    <div
      class="w-full max-w-md rounded-xl shadow-2xl p-8"
      :style="{ backgroundColor: 'var(--color-surface)' }"
    >
      <slot />
    </div>
  </div>
</template>
